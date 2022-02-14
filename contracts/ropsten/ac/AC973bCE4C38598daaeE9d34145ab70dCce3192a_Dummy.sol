/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

pragma solidity 0.5.16;

contract Dummy {
    uint256 private _whiteListCount;
    uint256 private _saleCount;

    bool private _isPublicSale;
    bool private _isPreSale;

    uint storedData;

    function getSaleCount() public view returns (uint) {
        return _saleCount;
    }

    function isPreSale()
        public
        view
        returns(bool)
    {
        return _isPreSale;
    }

    function _publicSaleMint(uint256 count)
        public
        payable
    {
        require(msg.value >= (0.05 ether * count), "Need to send ETH");

        // increase the saleCount for the count the user sent in
        for (uint256 i = 0; i < count; i++) {
            _saleCount++;
        }
    }
}