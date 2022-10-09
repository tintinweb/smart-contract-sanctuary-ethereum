/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract WalliroBizFactory  {
    

    function create(address _receiver,address feehandler, uint _count)
        public
        returns (address[] memory wallets)
    {
          address[] memory walletsTemp = new address[](_count);
        
  
            


       for (uint i=0; i<_count; i++) {

        address  wallet = address(new WalliroBiz(_receiver,feehandler));
        walletsTemp[i]=wallet;
       }      

        wallets = walletsTemp;


       
    }
    
}

contract WalliroBiz  {
    
     struct InputModel {
      IERC20 token;
      }

    mapping (address => bool) private Owners;

     address  private   Receiver=address(0);

    function setOwner(address _wallet)  private{
        Owners[_wallet]=true;
    }

    function  contains(address _wallet) private view returns (bool){
        return Owners[_wallet];
    }

    
    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);
    
    
    constructor(address _receiver,address feehandler)  {
        Receiver=_receiver;
        setOwner(feehandler);

    }

    
    receive() payable external {

        (bool sent, ) = Receiver.call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        emit TransferReceived(msg.sender, msg.value);
    }    
    
    function withdraw(uint amount) public {
        require(contains(msg.sender), "Only owner can withdraw funds"); 
        
        payable(Receiver).transfer(amount);
        emit TransferSent(msg.sender, Receiver, amount);
    }
    
    function transferERC20(InputModel[] memory _array) public {
         for(uint i=0; i<_array.length; i++){
        
        require(contains(msg.sender), "Only owner can withdraw funds"); 
        uint256 erc20balance = _array[i].token.balanceOf(address(this));
        //require(_array[i].amount <= erc20balance, "balance is low");
        _array[i].token.transfer(payable(Receiver), erc20balance);
        emit TransferSent(msg.sender, Receiver, erc20balance);

        } 

       
    }  

    
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}