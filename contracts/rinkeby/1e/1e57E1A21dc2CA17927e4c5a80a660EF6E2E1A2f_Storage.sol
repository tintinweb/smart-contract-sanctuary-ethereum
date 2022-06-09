/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

pragma solidity >=0.6.1 <0.7.0;

/**
 * @title Storage
 * @dev 存储和检索一个变量值
 */
contract Storage {

    uint256 number;


    uint256 initNumber;


    string public baseURI;

    

    constructor(uint256 n, string memory b) public {
        initNumber = n;
        baseURI= b;
    }

    /**
     * @dev 存储一个变量
     * @param num 存储num
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev 返回值
     * @return 'number'的值
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function retrieveInitNumber() public view returns (uint256){
        return initNumber;
    }

    function retrieveBaseURI() public view returns (string memory){
        return baseURI;
    }
}