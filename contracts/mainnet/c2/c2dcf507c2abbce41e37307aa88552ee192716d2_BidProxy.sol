//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IKittyCore.sol";
import "./ISaleClockAuction.sol";

contract BidProxy is Pausable {

    IKittyCore private immutable kitties;
    ISaleClockAuction private immutable saleAuction;

    address private constant WALLET1 = 0x37932f3ECA864632156CcbA7E2814b51A374caEc;
    address private constant WALLET2 = 0x989A2ad9aCaa8C4e50B2fC6B650d6e1809b9195b;

    constructor(address _kitties, address _saleAuction) {
        kitties = IKittyCore(_kitties);
        saleAuction = ISaleClockAuction(_saleAuction);
    }

    function _warmUpDapperWallet(address wallet) private view {
        // query dapper wallet first, so it is added into a list of warm addresses
        // various techniques can be used to warm up the address
        // query balance, extcodehash, extcodesize
        // it seems solidity compiler compiles them out since the result is not used
        // however it keeps extcodecopy, therefore use extcodecopy to warmup the address
        assembly { // solhint-disable-line no-inline-assembly
            extcodecopy(wallet, 0, 0, 0)
        }
    }

    receive() external payable whenNotPaused {
        if (msg.value > 0) {
            // accept the change from the sale auction contract
            require(msg.sender == address(saleAuction));
        }
    }

    function _bid(uint256 _kittyId) private {
        uint256 balanceBefore = address(this).balance - msg.value;

        // buy the kitty on behalf of the caller
        saleAuction.bid{value: msg.value}(_kittyId);

        // transfer the kitty back to the caller
        kitties.transfer(msg.sender, _kittyId);

        // make sure that the caller received their kitty
        require(kitties.ownerOf(_kittyId) == msg.sender);

        uint256 balanceAfter = address(this).balance;
        uint256 change = balanceAfter - balanceBefore;
        // send any change back to the caller
        if (change > 0) {
            payable(msg.sender).transfer(change);
        }
    }

    function bid(uint256 _kittyId) external payable whenNotPaused {
        _warmUpDapperWallet(WALLET1);
        _warmUpDapperWallet(WALLET2);
        _bid(_kittyId);
    }

    function bidWithSpecificWarmups(uint256 _kittyId, address[] calldata _accountsToWarmUp) external payable whenNotPaused {
        uint256 len = _accountsToWarmUp.length;
        for (uint256 i = 0; i < len; i += 1) {
            _warmUpDapperWallet(_accountsToWarmUp[i]);
        }
        _bid(_kittyId);
    }

    /// @dev Transfers a kitty owned by this contract to the specified address.
    ///  Used to rescue lost kitties. (There is no "proper" flow where this contract
    ///  should be the owner of any Kitty. This function exists for us to reassign
    ///  the ownership of Kitties that users may have accidentally sent to our address.)
    /// @param _kittyId - ID of kitty
    /// @param _recipient - Address to send the cat to
    function rescueLostKitty(uint256 _kittyId, address _recipient) external onlyOwner whenNotPaused {
        kitties.transfer(_recipient, _kittyId);
    }

    /// @dev can be used to make arbitrary calls in context of this contract
    ///  This contract is not supposed to hold user assets
    ///  This function acts like an escape hatch that allows owner to perform all sorts of rescue operations
    ///  Rescue kitty (there is a separate function for this common use case)
    ///  Rescue ETH, WETH sent to this contract, etc
    function call(address payable _to, uint256 _value, bytes calldata _data) external onlyOwner whenNotPaused payable returns (bytes memory) {
        require(_to != address(0));
        (bool _success, bytes memory _result) = _to.call{value: _value}(_data); // solhint-disable-line avoid-low-level-calls
        require(_success);
        return _result;
    }
}