// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyOwnable.sol";

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/proxy/Proxy.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice proxy contract of CellulaGame
///@dev upgrade limit：he new version of the contract can only add data on the basis of the previous version of the contract, 
///                   and the order of declaration must be behind the original data.。
contract CellulaGameProxy is Proxy, ProxyOwnable {

    using Address for address;

    /// @dev The address location of the CellulaGame contract is adopted in this way so as not to be overwritten by the data in the proxy contract itself

    bytes32 private constant _IMPLEMENT_ADDRESS_POSITION = keccak256("Cellula.Game.impl.address.84c2ce47");

    /// @dev Where the Owner is actually stored

    bytes32 private constant _OWNER_POSITION = keccak256("Cellula.Game.Proxy.owner.7e2efd65");

    /// @dev Set the address of the implement contract , only called by the owner

    function setImplementAddress(address cellulaGame)public onlyProxyOwner {

        require(cellulaGame.isContract(), "ADDRESS SHOULD BE CONTRACT");

        bytes32 position = _IMPLEMENT_ADDRESS_POSITION;

        assembly {

            sstore(position, cellulaGame)

        }

    }

    ///@dev return the address of the implement contract

    function getImplementAddress() public view returns (address) {

        return _implementation();

    }

    /// @dev override:return the address of the implement contract

    function _implementation() internal view virtual override returns (address) {

        bytes32 position = _IMPLEMENT_ADDRESS_POSITION;

        address impl;

        assembly {

            impl := sload(position)

        }

        return impl;

    }


    function _storeProxyOwner(address _owner) internal override {

        bytes32 position = _OWNER_POSITION;

        assembly {

            sstore(position, _owner)

        }

    }


    function _loadProxyOwner() internal view override returns (address) {

        bytes32 position = _OWNER_POSITION;

        address _owner;

        assembly {

            _owner := sload(position)

        }

        return _owner;

    }

}