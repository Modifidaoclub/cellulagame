// SPDX-License-Identifier: GPL-3.0

/* 
     */

pragma solidity ^0.8.0;

import "./CellulaAccessControl.sol";

contract CellulaNumericalControl is CellulaAccessControl{


	uint256 public mintPrice = 0; // 1000000000000000000;
    uint256 public buildPrice = 0; //1000000000000000000;
	
	//Add whitelist
    mapping(address => bool) public whiteList;
	
	// Modify mint price
	function addWhiteList(address[] calldata whiteLists) public CtoOnly {
        address[] memory _whiteList = whiteLists;
        for (uint256 i = 0; i < _whiteList.length; i++) {
            whiteList[_whiteList[i]] = true;
        }
    }
	
    // Modify mint price
    function setMintPrice(uint256 amount) public CooOnly {
        mintPrice = amount;
    }

    // Modify build price
    function setBuildPrice(uint256 amount) public CooOnly {
        buildPrice = amount;
    }

    //withdraw eth from the contract
    function withdraw(uint256 amount) public CooOnly {
        require(amount <= address(this).balance, "Insufficient balance");
        cooAddress.transfer(amount);
    }
	
	//Determine if it is on the whitelist
    function isWhiteList(address user)     
	public
    view
    returns (bool){
        return whiteList[user];
    }
}