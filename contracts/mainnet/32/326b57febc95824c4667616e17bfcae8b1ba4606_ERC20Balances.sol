/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
}

contract ERC20Balances {
    
    function balancesWithAccount(address _account, IERC20[] memory _tokens) public view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](_tokens.length + 1);
        uint256 ethBal = payable(_account).balance;
        results[0] = ethBal;
        for(uint idx = 0; idx < _tokens.length; idx++){
            try _tokens[idx].balanceOf(_account) returns (uint256 _val) {
                results[idx+1] = _val;
            } catch Error(string memory /*reason*/) {
                results[idx+1] = 0;
            } catch {
                results[idx+1] = 0;
            }
        }
        return results;
    }

    function balancesWithToken(IERC20 _token, address[] memory _acounts) public view returns (uint256[] memory) {
        uint256[] memory results = new uint256[](_acounts.length);
        for(uint idx = 0; idx < _acounts.length; idx++){
            try _token.balanceOf(_acounts[idx]) returns (uint256 _val) {
                results[idx+1] = _val;
            } catch Error(string memory /*reason*/) {
                results[idx+1] = 0;
            } catch {
                results[idx+1] = 0;
            }
        }
        return results;
    }

}