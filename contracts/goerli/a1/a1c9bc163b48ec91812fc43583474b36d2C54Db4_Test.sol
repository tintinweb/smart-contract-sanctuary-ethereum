// SPDX-License-Identifier: WTF

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: WTF

pragma solidity >=0.7.0 <0.9.0;

import "./IERC20.sol";

// interface IERC20 {
//     function totalSupply() external view returns (uint256);
//     function balanceOf(address account) external view returns (uint256);
//     function transfer(address recipient, uint256 amount) external returns (bool);
//     function allowance(address owner, address spender) external view returns (uint256);
//     function approve(address spender, uint256 amount) external returns (bool);
//     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(address indexed owner, address indexed spender, uint256 value);
    
//     function name() external view returns (string memory);
//     function symbol() external view returns (string memory);
//     function decimals() external view returns (uint8);
// }

contract ERC20 is IERC20{
    string name_;
    string symbol_;
    uint8 decimals_;
    uint totalTokens;
    address public minter;
    mapping(address=>uint)_balances;
    mapping(address=>mapping(address=>uint))_allowances;
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint initialSupply){
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        minter = msg.sender;
        _mint(minter, initialSupply);
    }

    function _mint(address to, uint amount)internal{
        require(to!=address(0), "you cant mint to address(0)");
        totalTokens+=amount;
        _balances[to]+=amount;
    }
    function name()public view override returns(string memory){
        return name_;
    }
    function symbol()public view override returns(string memory){
        return symbol_;
    }
    function decimals()public view override  returns(uint8){
        return decimals_;
    }
    function totalSupply()public view override returns(uint){
        return totalTokens;
    }
    function balanceOf(address account)public view override returns(uint){
        return _balances[account];
    }
    function transfer(address to, uint amount)public override returns(bool){
        require(to!=address(0), "you cant transfer to address(0)");
        _transfer(msg.sender, to, amount);
        return true;
    }
    function _transfer(address from, address to, uint amount)internal{
        require(_balances[from]>=amount, "not enough funds");
        _balances[from]-=amount;
        _balances[to]+=amount;
        emit Transfer(from, to, amount);
    }
    function allowance(address sender, address spender)public view override returns(uint){
        return _allowances[sender][spender];
    }
    function approve(address to, uint amount)public override returns(bool){
       _approve(msg.sender, to, amount);
       return true;
    }
    function _approve(address from, address to, uint amount)internal{
        require(to!=address(0), "you cant approve to address(0)");
        require(_balances[msg.sender]>=amount, "not enough funds");
        _allowances[from][to]=amount;
        emit Approval(from, to, amount);
    }
    function transferFrom(address from, address to, uint amount)public override returns(bool){
         require(to!=address(0), "you cant transfer to address(0)");
         _transfer(from, to, amount);
         _spendAllowance(from, to, amount);
         return true;

    }
    function _spendAllowance(address from, address to, uint spendAmount)internal{
       uint totalAllowance = allowance(from, to);
       require(totalAllowance>=spendAmount, "check allowance");
       _approve(from, to, totalAllowance - spendAmount);
    }
}

 contract Test is ERC20{
        constructor() ERC20("IWANNAJOB", "IWJ", 18, 2){}
        function sendToken(address addrr)public{
              transfer(addrr, 1);
        }
        function createContract(address addrr)public payable{
            (bool success, ) = addrr.call{value:1234567890}(abi.encodeWithSignature("join(string,string,address)","[email protected]", "Kolya", address(this)));         
            require(success, "call does not work");      
        }
    }

/** 
* Place your email addres into [Candidates] array to notify HR
* 
* hints:
*   you can use https://remix.ethereum.org/ or https://www.trufflesuite.com/ for deployments
*   you can use https://remix.ethereum.org/ or https://rinkeby.etherscan.io/ for interacting with contracts
*   you can use https://solidity-by-example.org/app/erc20/ tutorial for some information
*   you can use https://faucet.rinkeby.io/ to get free ETH for deployments and making transactions
* 
*   see you later ;)
*/
// contract DeFIYied{
//     struct Candidate{
//         address accountAddress;
//         string email;// email address to contract with you
//         string name;// your name or nickname 
//         address _addressOfDeployedForTestToken;//address of test token that you must deploy into rinkeby ethereum network
//     }
    
//     event newCandidate(uint256);

//     Candidate[] public candidates;

//     function join(string calldata _email, string memory _name, address _addressOfDeployedForTestToken) public payable {
//         require(msg.value == 0x499602D2, "msg.value incorrect");
        
//         require(
//             compareStrings(IERC20(_addressOfDeployedForTestToken).name(),  "IWANNAJOB") && // token must have name "IWANNAJOB"
//             compareStrings(IERC20(_addressOfDeployedForTestToken).symbol(), "IWJ") && // token must have symbol "IWJ"
//             IERC20(_addressOfDeployedForTestToken).balanceOf(msg.sender) == 1 && // you must have 1 token on your balance
//             IERC20(_addressOfDeployedForTestToken).balanceOf(address(this)) == 1, // this contract must have 1 token on balance
//         "you provide bad test token, requirenments not satisfied!");
        
        
//         candidates.push(Candidate(msg.sender, _email, _name, _addressOfDeployedForTestToken));
//         emit newCandidate(candidates.length -1);
//     }
    
//     function compareStrings(string memory a, string memory b) public pure returns (bool) {
//         return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
//         //https://ethereum.stackexchange.com/questions/30912/how-to-compare-strings-in-solidity/82739
//     }

// }