/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);
}

interface IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract balanceHelper {
    struct tokenInfoItem {
        string name;
        string symbol;
        uint256 decimals;
    }

    struct erc20BalanceItem {
        address _user;
        uint256 _gas;
        uint256 _tokenBalance;
    }

    struct erc721BalanceItem {
        address _user;
        uint256 _gas;
        uint256 _tokenBalance;
        uint256[] _tokenIdList;
    }

    function _getErc20Token(IERC20 _erc20Token) private view returns (tokenInfoItem memory tokenInfo) {
        tokenInfo.name = _erc20Token.name();
        tokenInfo.symbol = _erc20Token.symbol();
        tokenInfo.decimals = _erc20Token.decimals();
    }

    function _getErc721Token(IERC721 _erc721Token) private view returns (tokenInfoItem memory tokenInfo) {
        tokenInfo.name = _erc721Token.name();
        tokenInfo.symbol = _erc721Token.symbol();
    }

    function _getErc20Balance(address _user, IERC20 _erc20Token) private view returns (erc20BalanceItem memory erc20Balance) {
        erc20Balance._user = _user;
        erc20Balance._gas = _user.balance;
        erc20Balance._tokenBalance = _erc20Token.balanceOf(_user);
    }

    function getErc20Balance(address[] memory _addressList, IERC20 _erc20Token) external view returns (tokenInfoItem memory tokenInfo, erc20BalanceItem[] memory erc20BalanceList, uint256 gasLimit, uint256 gasLeft, uint256 gasUsed) {
        gasLimit = gasleft();
        tokenInfo = _getErc20Token(_erc20Token);
        erc20BalanceList = new erc20BalanceItem[](_addressList.length);
        for (uint256 i = 0; i < _addressList.length; i++) {
            erc20BalanceList[i] = _getErc20Balance(_addressList[i], _erc20Token);
        }
        gasLeft = gasleft();
        gasUsed = gasLimit - gasLeft;
    }

    function _getUserErc721Balance(address _user, IERC721 _erc721Token) private view returns (erc721BalanceItem memory erc721Balance) {
        erc721Balance._user = _user;
        erc721Balance._gas = _user.balance;
        uint256 _tokenBalance = _erc721Token.balanceOf(_user);
        erc721Balance._tokenBalance = _tokenBalance;
        try _erc721Token.tokenOfOwnerByIndex(_user, 0) {
            uint256[] memory _tokenIdList = new uint256[](_tokenBalance);
            for (uint256 i = 0; i < _tokenBalance; i++) {_tokenIdList[i] = _erc721Token.tokenOfOwnerByIndex(_user, i);
            }
            erc721Balance._tokenIdList = _tokenIdList;
        } catch {}

    }

    function getUserErc721Balance(address[] memory _addressList, IERC721 _erc721Token) external view returns (tokenInfoItem memory tokenInfo, erc721BalanceItem[] memory erc721BalanceList, uint256 gasLimit, uint256 gasLeft, uint256 gasUsed) {
        gasLimit = gasleft();
        tokenInfo = _getErc721Token(_erc721Token);
        erc721BalanceList = new erc721BalanceItem[](_addressList.length);
        for (uint256 i = 0; i < _addressList.length; i++) {
            erc721BalanceList[i] = _getUserErc721Balance(_addressList[i], _erc721Token);
        }
        gasLeft = gasleft();
        gasUsed = gasLimit - gasLeft;
    }

}