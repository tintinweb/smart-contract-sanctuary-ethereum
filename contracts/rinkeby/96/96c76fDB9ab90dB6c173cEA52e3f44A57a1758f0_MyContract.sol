// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Router.sol";

contract MyContract {
    string private name;
    
    address public  constant router = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;


    address public constant  busdToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    address public  constant dvifiToken = 0x0d5B2F4B7E9484981296E76c39E7245Bc19a3c3a;
    address[] public busdToDVIPath = [busdToken, dvifiToken];


    constructor() {
        name = "Test Name";
    }

    function changeName(string memory _name) public {
        name = _name;
    }

    function getName() public view returns (string memory) {
        return name;
    }
    function getPrice() public view returns (uint256 price){
        uint256[] memory pricePath = Router(router).getAmountsOut(1000000000000000000, busdToDVIPath);
        return pricePath[1];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract Router {
  function addLiquidity(
   address tokenA,
   address tokenB,
   uint amountADesired,
   uint amountBDesired,
   uint amountAMin,
   uint amountBMin,
   address to,
   uint deadline
  ) external returns(uint amountA, uint amountB, uint liquidity) {}
  function getAmountsOut(uint amountIn, address[] memory path) public view returns (uint[] memory amounts){}

}