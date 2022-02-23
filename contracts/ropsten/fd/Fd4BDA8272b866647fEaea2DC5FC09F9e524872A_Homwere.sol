// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Erc20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

interface Tkn{
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Homwere is ERC20, AccessControl {
    using SafeMath for uint256;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    address contractOwner;
    uint256 burnLimit;

    struct AdminPool{
        address payable Admin;
        bool Sing1;
        address SingAdr1;
        bool Sing2;
        address SingAdr2;
        uint txid;
        bool status;
        bool del;
    }

    AdminPool[] adminLog;

    event TknWithDraw(address indexed Spender, uint Amount, address contractAdr);

    event addAdmnAdrr( address indexed Adr,uint txid,address reqstr);

    modifier onlyAdmin (){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    //constructor that accepts admin address once deploying
    constructor() ERC20("BUSD", "BUSD") {
        _mint(_msgSender(), 300000000 * 10**18);
        burnLimit = 300000000 * 10**18;
        contractOwner = _msgSender();
        _setupRole(BURNER_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //To add a burner address
    function addNewBurner(address newBurner) public onlyAdmin{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        grantRole(BURNER_ROLE, newBurner);
    }

    //To remove a burner address
    function removeCurrentBurner(address rejectedBurner) public onlyAdmin{
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        revokeRole(BURNER_ROLE, rejectedBurner);
    }

    //This function burns the token 
    //It calls burn which calls _burn
    function burnTokens(uint256 amount) public {
        require(hasRole(BURNER_ROLE, _msgSender()), "Caller is not a burner");
        require(_msgSender() != address(0), "unknown address");
        require(totalSupply() > burnLimit, "you cant burn any further");
        burn(amount);
    }

    function burn(uint256 amount) internal virtual {
        super._burn(contractOwner, amount);
    }

    //This function makes it possible for contract to be able to withdraw network token
    function withdrawNetworkTkn() public returns(uint){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        uint conBal = address(this).balance;
        payable(msg.sender).transfer(conBal);

        emit TknWithDraw(msg.sender,conBal, address(this));

        return conBal;
    }

    //This function makes it possible for contract to be able to withdraw erc token
    function withdrawERC(uint amt, address contractAdr) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        Tkn Token = Tkn(contractAdr);

        uint256 sndtk = (amt) * (10 ** uint256(18 ));

        Token.transfer(msg.sender,sndtk);

        emit TknWithDraw(msg.sender,sndtk, contractAdr);

    }

    //This function makes it possible for contract to be able to receive network
    receive() external payable{
        
    }
    
    fallback() external payable{
        
    }
}