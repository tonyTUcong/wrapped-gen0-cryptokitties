// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "./WrappedCryptoKitties.sol";

contract WrappedGen0CryptoKitties is  WrappedCryptoKitties {
        
    constructor(address kittyCore_, string memory name_, string memory symbol_) 
      WrappedCryptoKitties(kittyCore_, name_, symbol_)
    {
        
    }


    function _check(uint256  kittyId) internal view override {
         (,,,,,,,,uint256 generation,) = kittyCore.getKitty(kittyId);
         require(generation == 0, 'this kitty must be Gen0');
    }
}
