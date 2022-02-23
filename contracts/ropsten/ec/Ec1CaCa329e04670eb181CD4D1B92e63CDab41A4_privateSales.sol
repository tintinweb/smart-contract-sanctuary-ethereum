// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Erc20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";
import "./IERC20.sol";

contract privateSales is AccessControl{
    /* ========== STATE VARIABLES ========== */
    //address public  contractAdr;
    uint256 public airDropAmt;
    address public homwereAdr;

    mapping(address => uint256) private contractAdrs;
    mapping (address => bool) adrParticip;

    modifier onlyAdmin (){
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    event tknWithDraw(address indexed Spender, uint Amount, address contractAdr);

    constructor(address _homwereAdr) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        homwereAdr = _homwereAdr;
    }

    function setPrice(address _conaddress, uint256 _price) public onlyAdmin{
        contractAdrs[_conaddress] = _price;
    }

    function withdrawERC(uint amt, address _contractAdr) public onlyAdmin {
        IERC20 Token = IERC20(_contractAdr);

        Token.transfer(msg.sender,amt);

        emit tknWithDraw(msg.sender,amt, _contractAdr);

    }

    function buyToken(address _conaddress, uint256 _amt) public {
        IERC20 Token = IERC20(_conaddress);
        IERC20 homTkn = IERC20(homwereAdr);
        require(Token.balanceOf(_msgSender()) >= _amt, "INSUFFICIENT ERC20 TOKEN AMOUNT FOR VALUE PROVIDED");
        require(adrParticip[_msgSender()] == false,"ACCOUNT HAVE ALREADY PARTICIPATED ON THE PRIVATE SELL");
        require(contractAdrs[_conaddress] > 0,"ACCOUNT HAVE ALREADY PARTICIPATED ON THE PRIVATE SELL");
        if(checkAllowance(_conaddress) >= _amt){
            Token.transferFrom(_msgSender(),address(this), _amt);

            uint256 Quan = contractAdrs[_conaddress] / _amt;

            homTkn.transfer(_msgSender(), Quan);

            adrParticip[_msgSender()] = true;
        }
        
    }

    function checkAllowance(address _conaddress)public view returns(uint256 allowanceAmt){
        IERC20 Token = IERC20(_conaddress);
        return Token.allowance(_msgSender(), address(this));
    }

}