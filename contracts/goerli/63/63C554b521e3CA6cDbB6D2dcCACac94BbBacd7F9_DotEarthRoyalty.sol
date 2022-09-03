//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract DotEarthRoyalty {
    event Received(address from, uint256 amount);

    uint96 public dotEarthTreasuryNumerator;
    uint96 public dotEarthFundNumerator;

    address payable public dotEarthTreasuryWallet;
    address payable public dotEarthFundWallet;

    constructor(
        uint96 dotEarthTreasuryNumerator_,
        uint96 dotEarthFundNumerator_,
        address payable dotEarthTreasuryWallet_,
        address payable dotEarthFundWallet_
    ) {
        _prevalidateRolaty(
            dotEarthTreasuryNumerator_,
            dotEarthFundNumerator_,
            dotEarthTreasuryWallet_,
            dotEarthFundWallet_
        );
        dotEarthTreasuryNumerator = dotEarthTreasuryNumerator_;
        dotEarthFundNumerator = dotEarthFundNumerator_;
        dotEarthTreasuryWallet = dotEarthTreasuryWallet_;
        dotEarthFundWallet = dotEarthFundWallet_;
    }

    function feeDenominator() public pure returns (uint96) {
        return 10000;
    }

    function _prevalidateNumeratorAssigment(
        uint96 dotEarthTreasuryNumerator_,
        uint96 dotEarthFundNumerator_
    ) internal pure {
        //solhint-disable-next-line reason-string
        require(
            dotEarthTreasuryNumerator_ + dotEarthFundNumerator_ <=
                feeDenominator(),
            "DotEarthRoyalty: sum of numerators greater than feeDenominator"
        );
    }

    function _prevalidateAddresses(
        address dotEarthTreasuryWallet_,
        address dotEarthFundWallet_
    ) internal pure {
        //solhint-disable-next-line reason-string
        require(
            dotEarthTreasuryWallet_ != address(0),
            "DotEarthRoyalty: dotEarthTreasuryWallet_ address cannot be zero"
        );
        //solhint-disable-next-line reason-string
        require(
            dotEarthFundWallet_ != address(0),
            "DotEarthRoyalty: dotEarthFundWallet_ address cannot be zero"
        );
    }

    function _prevalidateRolaty(
        uint96 dotEarthTreasuryNumerator_,
        uint96 dotEarthFundNumerator_,
        address dotEarthTreasuryWallet_,
        address dotEarthFundWallet_
    ) internal pure {
        _prevalidateAddresses(dotEarthTreasuryWallet_, dotEarthFundWallet_);
        _prevalidateNumeratorAssigment(
            dotEarthTreasuryNumerator_,
            dotEarthFundNumerator_
        );
    }

    function balance() public view returns (uint256) {
        return address(this).balance;
    }

    function sumOfNumerators() public view returns (uint96) {
        return dotEarthFundNumerator + dotEarthTreasuryNumerator;
    }

    function splitBalance() public {
        uint256 balance_ = balance();
        //solhint-disable-next-line reason-string
        require(balance_ > 0, "DotEarthRoyalty: Cannot withdraw 0 balance");

        uint256 forTreasury = (balance_ * dotEarthTreasuryNumerator) /
            feeDenominator();
        uint256 forFund = (balance_ * dotEarthFundNumerator) / feeDenominator();

        dotEarthTreasuryWallet.transfer(forTreasury);
        dotEarthFundWallet.transfer(forFund);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}