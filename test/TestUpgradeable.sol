// SPDX-License-Identifier: GPL-3.0

/* 
     */

pragma solidity ^0.8.0;
import"../CellulaGame.sol";

/*
This contract is not a business contract, it is only used to test the upgrade framework
*/

contract TestUpgradeable is CellulaGame {
	
    //test code 
    string  public testCode;

	
    function setTestCode(string calldata code) public AdminOnly {
        testCode = code;
    }
	
	function upgradeableTokenUrl(uint256 tokenId) public view  returns (string memory) {
        return tokenURI(tokenId);
    }


}