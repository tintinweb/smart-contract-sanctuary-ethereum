// SPDX-License-Identifier: MIT
pragma solidity ^0.5.0;

import 'ERC20.sol';
import 'ERC20Mintable.sol';
import "ERC20Detailed.sol";

import 'MintedCrowdsale.sol';
import 'TimedCrowdsale.sol';


contract RegenToken is ERC20, ERC20Mintable, ERC20Detailed {
    constructor(uint256 initialSupply, address beneficiary) ERC20Detailed("Regen Space", "REGENS", 18) public {
        _mint(beneficiary, initialSupply);
    }
}

contract RegenCrowdsale is Crowdsale, MintedCrowdsale {
    constructor(uint256 rate, address payable wallet, IERC20 token) MintedCrowdsale() Crowdsale(rate, wallet, token) public {

    }

    function _forwardFunds() internal {
        (bool success, ) = wallet().call.value(msg.value).gas(200000)(""); // Due to gas limits happening when sending to Gnosis Safe
        require(success, "Transfer failed.");
    }
}

contract Deployer {
    constructor(address payable multisig) public {
        ERC20Mintable token = new RegenToken(1000000 ether, multisig);

        Crowdsale crowdsale = new RegenCrowdsale(1000, multisig, token);

        token.addMinter(address(crowdsale));
        token.renounceMinter();
    }
}