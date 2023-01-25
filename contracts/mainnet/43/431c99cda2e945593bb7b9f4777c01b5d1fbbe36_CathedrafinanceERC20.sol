//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import {ERC20} from "./ERC20.sol";
import {IERC165} from "./IERC165.sol";
import {ICathedrafinanceERC20} from "./ICathedrafinanceERC20.sol";
import "./OFTCore.sol";

/// @title Cathedrafinance
/// @author Cathedrafinance Dev
/// @notice ERC20 implementation ontop of Layer Zero
/// @notice Ownable is inherited through OFTCore
/// which needs to be maintained either with a governance system or
/// multisig in order to update its Layer Zero configurations.

contract CathedrafinanceERC20 is OFTCore, ERC20, ICathedrafinanceERC20 {
    error NotOwner();
    error MinterSet();

    /// @notice address who is available to mint tokens, set to the treasury
    /// in order to implement the bonding curve.

    address public minter;

    constructor(address _lzEndpoint)
        ERC20("Cathedrafinance", "ICTF")
        OFTCore(_lzEndpoint)
    {}

    function mint(address _to, uint256 _amount) external override onlyMinter {
        _mint(_to, _amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OFTCore, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICathedrafinanceERC20).interfaceId ||
            interfaceId == type(IERC20).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function circulatingSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return totalSupply();
    }

    function _debitFrom(
        address _from,
        uint16,
        bytes memory,
        uint256 _amount
    ) internal virtual override {
        address spender = _msgSender();
        if (_from != spender) {
            _spendAllowance(_from, spender, _amount);
        }
        _burn(_from, _amount);
    }

    function _creditTo(
        uint16,
        address _toAddress,
        uint256 _amount
    ) internal virtual override {
        _mint(_toAddress, _amount);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(
            msg.sender == minter || msg.sender == owner(),
            "Only minter can call this"
        );
        _;
    }
}