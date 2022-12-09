pragma solidity ^0.8.7;

// ERC20 contract interface
interface Token {
    function balanceOf(address) external virtual view returns (uint);
}

contract BatchGetBalance {

    struct TokenBalanceReq {
        address addr;

        address token;
    }

    function tokenBalances(TokenBalanceReq[] calldata requests) external view returns (uint[] memory addrBalances) {
        addrBalances = new uint[](requests.length);

        for(uint i = 0; i < requests.length; i++) {
            TokenBalanceReq calldata tokenBalanceReq = requests[i];
            addrBalances[i] = Token(tokenBalanceReq.token).balanceOf(tokenBalanceReq.addr);
        }

        return addrBalances;
    }

    function ethBalances(address[] calldata addresses) external view returns (uint[] memory addrBalances) {
        addrBalances = new uint[](addresses.length);

        for(uint i = 0; i < addresses.length; i++) {
            addrBalances[i] = addresses[i].balance;
        }

        return addrBalances;
    }

}