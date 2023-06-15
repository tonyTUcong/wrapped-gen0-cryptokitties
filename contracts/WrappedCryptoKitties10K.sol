// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./WrappedCryptoKitties.sol";

contract WrappedCryptoKitties10K is WrappedCryptoKitties {

    function _checkBeforeMint(uint256 kittyId) internal virtual override {

        require(kittyId > 0 && kittyId <= 10000, "Invalid kittyId");

        super._checkBeforeMint(kittyId);
    }
}