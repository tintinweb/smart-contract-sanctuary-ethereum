// Built off of https://github.com/DeltaBalances/DeltaBalances.github.io/blob/master/smart_contract/deltabalances.sol
pragma solidity ^0.6.0;

// ERC20 contract interface
abstract contract Token {
    function balanceOf(address) external view virtual returns (uint256);

    function blockedBalanceOf(address) external view virtual returns (uint256);
}

contract BalanceChecker {
    /*
    Check the token balance of a wallet in a token contract

    Returns the balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address 
      - returns 0 if the contract doesn't implement balanceOf
  */
    function tokenBalance(address user, address token)
        public
        view
        returns (uint256)
    {
        // check if token is actually a contract
        uint256 tokenCode;
        assembly {
            tokenCode := extcodesize(token)
        } // contract code size

        // is it a contract and does it implement balanceOf
        (bool success, ) = token.staticcall(
            abi.encodeWithSignature("balanceOf(address)", user)
        );
        if (tokenCode > 0 && success) {
            return Token(token).balanceOf(user);
        } else {
            return 0;
        }
    }

    /*
    Check the blocked token balance of a wallet in a token contract

    Returns the blocked balance of the token for user. Avoids possible errors:
      - return 0 on non-contract address 
      - returns 0 if the contract doesn't implement blockedBalanceOf
  */
    function tokenBlockedBalance(address user, address token)
        public
        view
        returns (uint256)
    {
        // check if token is actually a contract
        uint256 tokenCode;
        assembly {
            tokenCode := extcodesize(token)
        } // contract code size

        // is it a contract and does it implement balanceOf
        (bool success, ) = token.staticcall(
            abi.encodeWithSignature("blockedBalanceOf(address)", user)
        );
        if (tokenCode > 0 && success) {
            return Token(token).blockedBalanceOf(user);
        } else {
            return 0;
        }
    }

    /*
    Check the token balances of a wallet for multiple tokens.
    Pass 0x0 as a "token" address to get ETH balance.

    Possible error throws:
      - extremely large arrays for user and or tokens (gas cost too high) 
          
    Returns a one-dimensional that's user.length * tokens.length long. The
    array is ordered by all of the 0th users token balances, then the 1th
    user, and so on.
  */
    function balances(address[] calldata users, address[] calldata tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory addrBalances = new uint256[](
            tokens.length * users.length
        );

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                if (tokens[j] != address(0x0)) {
                    addrBalances[addrIdx] = tokenBalance(users[i], tokens[j]);
                } else {
                    addrBalances[addrIdx] = users[i].balance; // ETH balance
                }
            }
        }

        return addrBalances;
    }

    /*
    Check the blocked token balances of a wallet for multiple tokens.
    Pass 0x0 as a "token" address to get ETH blocked balance.

    Possible error throws:
      - extremely large arrays for user and or tokens (gas cost too high) 
          
    Returns a one-dimensional that's user.length * tokens.length long. The
    array is ordered by all of the 0th users blocked token balances, then the 1th
    user, and so on.
  */

    function blockedBalances(
        address[] calldata users,
        address[] calldata tokens
    ) external view returns (uint256[] memory) {
        uint256[] memory addrBalances = new uint256[](
            tokens.length * users.length
        );

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                uint256 addrIdx = j + tokens.length * i;
                if (tokens[j] != address(0x0)) {
                    addrBalances[addrIdx] = tokenBlockedBalance(
                        users[i],
                        tokens[j]
                    );
                } else {
                    addrBalances[addrIdx] = users[i].balance; // ETH balance
                }
            }
        }

        return addrBalances;
    }
}