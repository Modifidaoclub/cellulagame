// SPDX-License-Identifier: GPL-3.0

/* 
     The Game of Life's basic rules:
        1．The state of each cell is determined by its own previous state and the previous states of the eight surrounding cells.
        2. If a cell has three neighboring cells that are alive, the cell becomes alive; if the cell was originally dead, it becomes alive, and if it was originally alive, it remains unchanged.
        3. If a cell has two neighboring cells that are alive, the cell's life or death state remains unchanged.
        4. In all other cases, the cell becomes dead; if the cell was originally alive, it becomes dead, and if it was originally dead, it remains unchanged.
     */
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./CellulaNumericalControl.sol";
import "./BitMap.sol";

contract CellulaGame is ERC721EnumerableUpgradeable, CellulaNumericalControl{
    using BitMaps for BitMaps.BitMap;

    uint256 immutable MAX_COUNT = 10;
    uint256 public current_round_number = 0;
    uint256 public immutable MAX_SUPPLY = 51100; // Mint & Synthesis Total Quantity
    uint256 immutable MAX_RANDOM_NUM = 511;
    uint256 public immutable MAX_NUMBER = 511; // Maximum casting quantity per round
    uint256 public immutable MAX_APES = 5110; // Maximum mint total quantity
    uint256 public immutable BLOCK_TIME = 2; //Set the time for each block
    uint32 public immutable EVOLUTION_TIME = 15 * 60; // Evolution time
    uint32 public immutable LIMIT_MINT_NUM = 9; //Maximum casting quantity per address

    BitMaps.BitMap private randomBitmap;

    struct Cellula {
        uint16 geneType; //1.Original gene 2.Splicing gene 3.Synthetic gene
        uint16 x;
        uint16 y;
        uint16 cooldownNum; //Cooling block
        uint32 id;
        uint32 livingCellTotal; //Living cell count
        uint64 combineBlock; //Last participated combination block
        uint64 bornBlock; //Birth block
        bytes32 evolveSeed;//Evolution random seed
        BitMaps.BitMap bitmap; //Original gene information
        uint256[] parentTokenIds;
    }

    Cellula[] cellulaPool; //NFT pool

    mapping(address => uint8) public userMintNum; // Number of tokens minted per user

    uint256 public mintedNum = 0; //Current mint quantity
	string private _baseUrl;

	//Initialization
    function initialize(string calldata name, string calldata symbol) public initializer {

        adminAddress = msg.sender;
		_baseUrl = "https://api.cellula.life/token/";
        __ERC721_init(name, symbol);
	}

    //Minting method
    function mint() external payable {
        uint256 tokenId = cellulaPool.length;
        require(
            tokenId < MAX_SUPPLY && mintedNum < MAX_APES,
            "tokenId out of range"
        );
        require(totalSupply() <= MAX_SUPPLY, "Out of stock");
        require(
            userMintNum[msg.sender] < LIMIT_MINT_NUM,
            "The maximum number of individual castings is 2"
        );
        if (!isWhiteList(msg.sender)) {
            require(msg.value == mintPrice, "Payment must be 1 ETH");
        }
        _mint(msg.sender, tokenId);
        mintedNum = mintedNum + 1;
        uint256 randomNum = getRandomNumber();
        //Obtain a random number between 1 and 511
        userMintNum[msg.sender] = userMintNum[msg.sender] + 1;
        Cellula storage cell = cellulaPool.push();
        cell.id = uint32(tokenId);
        cell.geneType = 1;
        cell.bornBlock = uint64(block.number);
        cell.evolveSeed = getEvolveSeed();
        cell.parentTokenIds = new uint256[](0);
        cell.x = 3;
        cell.y = 3;
        cell.bitmap.setBucket(0, randomNum);
        uint32 cellCount = 0;

        for (uint256 i = 0; i < 9; i++) {
            if (cell.bitmap.get(i)) {
                cellCount += 1;
            }
        }
        cell.livingCellTotal = cellCount;
    }

    //Get Cellula information
    function getCellula(uint256 tokenID)
    public
    view
    returns (
        uint256 x,
        uint256 y,
        string memory genes,
        uint16 geneType,
        uint256 cooldownNum,
        uint256 bornBlock,
        uint256 livingCellTotal,
        uint256 combineBlock,
        uint256[] memory parentTokenIds
    )
    {
        Cellula storage cell = cellulaPool[tokenID];
        x = cell.x;
        y = cell.y;
        geneType = cell.geneType;
        cooldownNum = cell.cooldownNum;
        bornBlock = cell.bornBlock;
        parentTokenIds = cell.parentTokenIds;
        livingCellTotal = cell.livingCellTotal;
        genes = decodeGenes(tokenID);
        combineBlock=cell.combineBlock;
    }

    function getRLESting(uint256 tokenId)
    public
    view
    returns (string memory rleSting)
    {
        Cellula storage cell = cellulaPool[tokenId];
        string memory rle = decodeGenes(tokenId);
        rleSting = string(
            abi.encodePacked(
                "x = ",
                Strings.toString(cell.x),
                ", y = ",
                Strings.toString(cell.y),
                "\n",
                rle
            )
        );
    }

    //Serialize and display gene information
    function getGenesSequence(uint256 tokenID)
    public
    view
    returns (string memory genes)
    {
        Cellula storage cell = cellulaPool[tokenID];
        string memory result;
        uint256 count = cell.x * cell.y;
        for (uint256 i = count; i > 0; i--) {
            bool value = cell.bitmap.get(i - 1);
            if (value) {
                result = string(abi.encodePacked(result, "1"));
            } else {
                result = string(abi.encodePacked(result, "0"));
            }
        }

        console.log(result);

        return result;
    }

    // New synthesis method
    // 3*3 synthesis 9*9
    // Input parameters: 2-9 arrays, where the first element of the array represents the tokenID, and the second element represents the position (1-9)
    // Example: [[1, 1], [2, 3]] represents placing tokens with tokenID 1 and 2 in positions 1 and 3, respectively
    function combineCells(uint256[][] calldata tokensPositions) public payable {
        require(msg.value >= buildPrice, "Payment must be 1 ETH");
        require(totalSupply() <= MAX_SUPPLY, "Out of stock");
        require(
            tokensPositions.length >= 2 && tokensPositions.length <= 9,
            "You can only use 2-9 combinations!"
        );
        for (uint256 i = 0; i < tokensPositions.length; i++) {
            uint256 tokenID = tokensPositions[i][0];
            Cellula storage cell = cellulaPool[tokenID];
            require(isNFTOwnedOrApproved(tokenID), "Invalid NFT owner");
            require(combinable(cell.id), "NFT is unavailable");
            require(tokensPositions[i][1] < 10, "position error");
            for (uint256 j = i + 1; j < tokensPositions.length; j++) {
                require(
                    tokensPositions[i][0] != tokensPositions[j][0],
                    "Duplicate NFTs detected"
                );
                require(
                    tokensPositions[i][1] != tokensPositions[j][1],
                    "Two NFTs cannot be placed in the same position"
                );
            }
        }

        uint256 newTokenId = cellulaPool.length;
        Cellula storage newCell = cellulaPool.push();
        newCell.id = uint32(newTokenId);
        newCell.geneType = 2;
        newCell.bornBlock = uint64(block.number);
        newCell.evolveSeed = getEvolveSeed();
        newCell.x = 9;
        newCell.y = 9;

        uint32 cellCount = 0;

        for (uint256 count = 0; count < tokensPositions.length; count++) {
            uint256 parentTokenID = tokensPositions[count][0];

            Cellula storage parentCell = cellulaPool[parentTokenID];
            parentCell.combineBlock = uint64(block.number);

            newCell.parentTokenIds.push(parentTokenID);
            uint256 position = tokensPositions[count][1];

            uint256 x = ((position - 1) % 3) * 3;
            uint256 y = ((position - 1) / 3) * 3;

            (uint256 top, uint256 mid, uint256 bottom) = getDigits(
                parentCell.bitmap.getBucket(0)
            );
            uint256 Mask = 81 - (x + 9 * y) - 3;
            newCell.bitmap.setBucket(0, bottom << Mask);
            newCell.bitmap.setBucket(0, mid << (Mask - 9));
            newCell.bitmap.setBucket(0, top << (Mask - 18));

            cellCount = cellCount + parentCell.livingCellTotal;
        }
        newCell.livingCellTotal = cellCount;

        for (uint256 count = 0; count < tokensPositions.length; count++) {
            uint256 parentTokenID = tokensPositions[count][0];
            Cellula storage parentCell = cellulaPool[parentTokenID];
            parentCell.cooldownNum = uint16((cellCount * 15 * 60) / BLOCK_TIME);
        }

        _mint(msg.sender, newTokenId);
    }

    // Check if it can be used for synthesis
    function combinable(uint256 tokenId) public view returns (bool) {
        Cellula storage cell = cellulaPool[tokenId];
        if (cell.geneType != 1) {
            return false;
        }
        return block.number >= (cell.combineBlock + cell.cooldownNum);
    }

    //Obtain 512 unique random numbers for 10 rounds
    function getRandomNumber() public returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        for (uint256 i = 0; i < MAX_RANDOM_NUM; i++) {
            uint256 index = (randomNumber + i) % MAX_RANDOM_NUM;
            if (!randomBitmap.get(index)) {
                randomBitmap.set(index);
                return index + 1;
            }
        }

        if (current_round_number < MAX_COUNT) {
            randomBitmap.unsetBucket(0, 0);
            randomBitmap.unsetBucket(1, 0);
            current_round_number += 1;
            return getRandomNumber();
        } else {
            revert("All numbers have been used");
        }
    }

    function decodeGenes(uint256 tokenId)
    internal
    view
    returns (string memory)
    {
        // Convert the bitmap to a 2D array

        Cellula storage cell = cellulaPool[tokenId];
        uint256 width = cell.x;
        uint256 height = cell.y;

        uint256[][] memory pixels = new uint256[][](height);
        for (uint256 i = 0; i < height; i++) {
            pixels[i] = new uint256[](width);
            for (uint256 j = 0; j < width; j++) {
                pixels[i][j] = cell.bitmap.get(
                    width * height - (i * width + j) - 1
                )
                ? 1
                : 0;
            }
        }

        // Initialize an empty RLE string
        string memory rle = "";

        for (uint256 i = 0; i < height; i++) {
            uint256 runValue = pixels[i][0];
            uint256 runLength = 0;

            for (uint256 j = 0; j < width; j++) {
                uint256 pixelValue = pixels[i][j];

                if (pixelValue == runValue) {
                    runLength++;
                } else {
                    rle = string(
                        abi.encodePacked(
                            rle,
                            Strings.toString(runLength),
                            runValue == 1 ? "o" : "b"
                        )
                    );
                    runValue = pixelValue;
                    runLength = 1;
                }
            }
            rle = string(
                abi.encodePacked(
                    rle,
                    Strings.toString(runLength),
                    runValue == 1 ? "o" : "b",
                    "$"
                )
            );
        }

        return rle;
    }


    function getEvolutionaryAlgebra(uint256 tokenId)
    public
    view
    returns (uint256)
    {
        require(_exists(tokenId), "The tokenID does not exist");
        uint256 mintBlockNum = cellulaPool[tokenId].bornBlock;
        uint256 algebra = ((block.number - mintBlockNum) * BLOCK_TIME) /
        EVOLUTION_TIME;
        return algebra;
    }

    function lifeBaseRules(uint8[9] calldata cellGenes)
    public
    pure
    returns (uint8)
    {
        uint8 liveCellNum = 0;

        for (uint256 i = 0; i < 9; i++) {
            if ((i != 4) && (cellGenes[i] == 1)) {
                liveCellNum += 1;
            }
        }
        if (liveCellNum == 2) {
            return cellGenes[4];
        }
        return liveCellNum <= 1 || liveCellNum >= 4 ? 0 : 1;
    }

    function getEvolve(uint256 tokenID, uint256 generation)
    public
    view
    returns (uint256)
    {
        Cellula storage cell = cellulaPool[tokenID];
        bytes32 randomNumber = keccak256(
            abi.encodePacked(
                generation,
                cell.evolveSeed,
                getGenesSequence(tokenID)
            )
        );
        uint256 num = uint256(randomNumber);
        return num % 2;
    }

    function getEvolveSeed() internal view returns (bytes32) {
        return
        keccak256(
            abi.encodePacked(
                block.number,
                msg.sender,
                blockhash(block.timestamp - 1)
            )
        );
    }

    /* tools */

    function getDigits(uint256 number)
    internal
    pure
    returns (
        uint256 top,
        uint256 min,
        uint256 bottom
    )
    {
        // Create three masks to obtain different parts of the numbers
        uint256 mask1 = 0x7;
        //  00000111
        uint256 mask2 = 0x38;
        //  000111000
        uint256 mask3 = 0x1c0;
        //  111000000

        // Use the bitwise AND operator '&' and the right shift operator '>>' to obtain different parts of the numbers.
        uint256 digits1 = number & mask1;
        uint256 digits2 = (number & mask2) >> 3;
        uint256 digits3 = (number & mask3) >> 6;

        return (digits1, digits2, digits3);
    }


    function changeBaseURL(string calldata newBaseURL) public AdminOnly {
        _baseUrl = newBaseURL;
    }

    // Determine if the user has the authority to operate the NFT
    function isNFTOwnedOrApproved(uint256 tokenId)
    internal
    view
    returns (bool)
    {
        address owner = ownerOf(tokenId);
        if (owner == msg.sender) {
            return true;
        }
        return
        getApproved(tokenId) == msg.sender ||
        isApprovedForAll(owner, msg.sender);
    }

    receive() external payable {}

    function _baseURI() internal view override returns (string memory) {
        return _baseUrl;
    }
}