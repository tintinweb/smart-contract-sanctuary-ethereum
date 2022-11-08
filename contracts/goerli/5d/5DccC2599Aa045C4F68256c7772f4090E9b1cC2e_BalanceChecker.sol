pragma solidity 0.8.10;

interface ERC20Interface {
    // Get the account balance of another account with address _owner
    function balanceOf(address _owner) view external returns (uint256 balance);
}

contract BalanceChecker {

    constructor () {}

    function checkBalances(address[] calldata addressList, address[] calldata erc20TokenList) view external returns( uint256[][] memory){

        //Returns balances of erc20 tokens provided
        uint256 addressListLength = addressList.length;
        uint256 tokenListLength = erc20TokenList.length;
        uint256[][] memory  returnList  = new uint256[][](tokenListLength+1);

        for(uint256 i; i < tokenListLength; ++i) {
            uint256[] memory tmp = new uint256[](addressListLength);
            for(uint256 j; j < addressListLength; ++j) {
                uint256 balance = ERC20Interface(erc20TokenList[i]).balanceOf(addressList[j]);
                tmp[j] = balance;
            }
            returnList[i] = tmp;
        }

        //Returns ether balances for all addresses
        uint256[] memory ethValues = new uint256[](addressListLength);
        for(uint256 k; k < addressListLength; ++k) {
            ethValues[k] = addressList[k].balance;
        }
        returnList[tokenListLength] = ethValues;
        return returnList;
    }
}