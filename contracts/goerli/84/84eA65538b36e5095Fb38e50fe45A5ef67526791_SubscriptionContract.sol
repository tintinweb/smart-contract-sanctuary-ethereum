/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: FIG pg17
pragma solidity 0.8.17;


contract SubscriptionContract {

    address public tokenAddress;
    // DAI: address constant public tokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // USDC: address constant public tokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address owner;
    mapping(address => bool) admin;

    ERC20 token;

    struct Subscription {
        bool subscribed;
        uint256 balance;
        uint256 lock_end; //when funds get unlocked
        uint256 locked_balance;
    }

    mapping (address => Subscription) public sub_info;

    uint256 public treasury;

    event NewSubscriber(address subscriber,uint256 balance);
    event balance_update(address subscriber,uint256 new_balance);
    event treasury_withdrawal(address sender,address receiver,uint256 amount_sent,uint256 treasury_balance);


    modifier onlyOwner {
        require(msg.sender == owner ,"caller is not owner");
        _; //given function runs here
    }
    modifier onlyAdmin {
        require(admin[msg.sender] || msg.sender == owner ,"caller does not have the perms required");
        _; //given function runs here
    }
    modifier has_funds_available(uint256 _amount) {

        //if funds are currently locked
        if(sub_info[msg.sender].lock_end > block.timestamp){
            //requires that users unlocked funds are greater then _amount
            require(sub_info[msg.sender].balance - sub_info[msg.sender].locked_balance >= _amount,"subscribtion does not have enough available funds");
        }
        else {
            //requires that all user funds are greater then _amount
            require(sub_info[msg.sender].balance >= _amount,"subscribtion does not have enough funds");
        }
        _; //given function runs here
    }
    modifier is_subbed {
        require(sub_info[msg.sender].subscribed,"caller does not have a subscribtion");
        _; //given function runs here
    }

    constructor(address _tokenAddress){
        owner = msg.sender;

        tokenAddress = _tokenAddress;
        token = ERC20(tokenAddress);

    }


    //user functions
    //user functions
    //user functions
        function createSubscription(uint256 _amount) public {
            require(!(sub_info[msg.sender].subscribed),"caller is already subscribed");
           
            //create subscribtion 
            //sub_address.push(msg.sender);
            //sub_info[msg.sender].id = sub_address.length - 1;
            sub_info[msg.sender].subscribed = true;

            //if they chose to fund their subscribtion
            if(_amount > 0){
                require(token.allowance(msg.sender, address(this)) >= _amount,"caller has not approved this contract to pull these funds");
                require(token.balanceOf(msg.sender) >= _amount,"caller does not have enough tokens in their wallet to pull");

                //transefer tokens from users wallet to this contract
                bool transfer_success = (token.transferFrom(msg.sender, address(this), _amount));
                require(transfer_success,"token transfer failed");
                
                //credit the tokens in their subscribtion
                sub_info[msg.sender].balance += _amount;
            }

            emit NewSubscriber(msg.sender,_amount);
        }

        function deposit(uint256 _amount) public is_subbed {
            require(token.allowance(msg.sender, address(this)) >= _amount,"caller has not approved this contract to pull these funds");
            require(token.balanceOf(msg.sender) >= _amount,"caller does not have enough tokens in their wallet to pull");

            //transefer tokens from users wallet to this contract
            bool transfer_success = (token.transferFrom(msg.sender, address(this), _amount));
            require(transfer_success,"token transfer failed");

            //credit the tokens in their subscribtion
            sub_info[msg.sender].balance += _amount;

            emit balance_update(msg.sender,_amount);
        }

        function withdraw(uint256 _amount) public is_subbed has_funds_available(_amount) {
            
            //remove tokens from users balance
            sub_info[msg.sender].balance -= _amount;

            //send tokens from this contract to users wallet
            bool transfer_success = (token.transfer(msg.sender, _amount));
            require(transfer_success,"token transfer failed");

            emit balance_update(msg.sender,sub_info[msg.sender].balance);
        }


    //admin functions
    //admin functions
    //admin functions
        function transfer_ownership(address new_owner) external onlyOwner{
            owner = new_owner;
        }

        function change_admin_status(address _admin,bool _status) external onlyOwner{
            admin[_admin] = _status;
        }

        //add lock amount
        function lockSubscription(address sub_owner,uint256 _lockduration/*in hours*/,uint256 _locked_balance) public onlyAdmin{
            //local variables for gas optimizations 
            
            //address sub_owner = sub_address[_id];
            Subscription memory local_sub_info = sub_info[sub_owner];

            //checks if subscribtion has an active lock, if so locked funds stack
            //an input of 0 unlocks the subscribtion early
            if(local_sub_info.lock_end > block.timestamp && _lockduration > 0) {
                //checks that subscribtion has available funds to be locked inculding already locked funds
                require(_locked_balance + local_sub_info.locked_balance <= local_sub_info.balance,"subscribtion's available funds are not enough");

                //if the current lock period is smaller then the new lock period the lock period will be increased to the longer one
                //The longer of the 2 lock durations will take priority 
                if(local_sub_info.lock_end < block.timestamp + (_lockduration * 1 hours)){
                    sub_info[sub_owner].lock_end = block.timestamp + (_lockduration * 1 hours);
                }

                sub_info[sub_owner].locked_balance = _locked_balance + local_sub_info.locked_balance;
            } else {
                //checks that subscribtion has enough funds to be locked
                require(_locked_balance <= local_sub_info.balance,"subscribtion does not have enough funds to lock");
                
                //set unlock date
                sub_info[sub_owner].lock_end = block.timestamp + (_lockduration * 1 hours);

                //set locked balance
                sub_info[sub_owner].locked_balance = _locked_balance;
            }
        }

        function forceWithdraw(address sub_owner, uint256 _amount,bool return_funds) public onlyAdmin{
            //local variable for gas optimizations 
            Subscription memory local_sub_info = sub_info[sub_owner];

            //makes sure users account has enough funds to be withdrawn
            require(local_sub_info.balance >= _amount,"subscribtion does not have enough funds");
            
            //if the sub has an active lock
            if(local_sub_info.lock_end > block.timestamp){
                //amount is taken from the locked funds
                //ensures no underflow errors occur 
                if(local_sub_info.locked_balance >= _amount){
                    sub_info[sub_owner].locked_balance -= _amount;
                } else/*_amount is larger than locked_balance*/{
                    sub_info[sub_owner].locked_balance = 0;
                }
            }
            //funds are REMOVED from user balance and ADDED to the treasury
            sub_info[sub_owner].balance -= _amount;
            treasury += _amount;

            if(return_funds){
                returnFunds(sub_owner,local_sub_info.balance - _amount);
            }else {
                emit balance_update(sub_owner,local_sub_info.balance - _amount);
            }
        }

        
        function returnFunds(address sub_owner,uint256 _amount) public onlyAdmin{
            //local variable for gas optimizations 
            Subscription memory local_sub_info = sub_info[sub_owner];

            require(local_sub_info.balance >= _amount,"subscribtion does not have enough funds to withdraw");

            sub_info[sub_owner].balance -= _amount;
            bool transfer_success = (token.transfer(sub_owner, _amount));
            require(transfer_success,"token transfer failed");

            emit balance_update(sub_owner,local_sub_info.balance - _amount);
        }
        

        function treasury_withdraw(address _receiver,uint256 _amount) public onlyAdmin {
            require(_amount <= treasury,"treasury dose not have enough funds to withdraw the requested amount");

            bool transfer_success = (token.transfer(_receiver, _amount));
            require(transfer_success,"token transfer failed");

            emit treasury_withdrawal(msg.sender,_receiver,_amount,treasury);
        }

    //view functions
    //view functions
    //view functions

        function view_sub_info(address sub_owner) view external returns (bool subscribed, uint256 balance,bool isLocked,uint256 lock_end,uint256 lockedBalance) {
            Subscription memory local_sub_info = sub_info[sub_owner];

            return(
                local_sub_info.subscribed,
                local_sub_info.balance,
                local_sub_info.lock_end > block.timestamp,
                local_sub_info.lock_end,
                local_sub_info.locked_balance
            );
        }

}

interface ERC20 {
    function name() external view returns (string calldata); //
    function symbol() external view returns (string calldata); //
    function decimals() external view returns (uint8); //
    function totalSupply() external view returns (uint256); //
    function balanceOf(address _owner) external view returns (uint256 balance); //
    function transfer(address _to, uint256 _value) external returns (bool success); //
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success); //
    function approve(address _spender, uint256 _value) external returns (bool success); //
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);   

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}