// SPDX-License-Identifier: GPL-3.0

/* 
     */

pragma solidity ^0.8.0;


contract CellulaAccessControl {
	
    address public adminAddress;
    address payable public cooAddress;
    address public ctoAddress;
	
	modifier AdminOnly() {
        require(msg.sender == adminAddress, "Caller is not Admin");
        _;
    }

    modifier CooOnly() {
        require(msg.sender == cooAddress, "Caller is not COO");
        _;
    }
    modifier CtoOnly() {
        require(msg.sender == ctoAddress, "Caller is not CTO");
        _;
    }

    function changeAdmin(address newAddress) public AdminOnly {
        adminAddress = newAddress;
    }

    function changeCooAddress(address payable newAddress) public AdminOnly {
        cooAddress = newAddress;
    }

    function changeCtoAddress(address newAddress) public AdminOnly {
        ctoAddress = newAddress;
    }

}