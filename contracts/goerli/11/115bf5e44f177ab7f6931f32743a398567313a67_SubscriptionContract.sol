/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.17;


contract SubscriptionContract {

    //address public tokenAddress;
    address constant public tokenAddress = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C; // GoerliUSDC 

    // DAI: address constant public tokenAddress = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // USDC: address constant public tokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address public owner;
    mapping(address => bool) public admin;
    mapping(address => bool) public whitelist;
    
    ERC20 token;

    struct Subscription {
        uint256 balance;
        uint256 lockedBalance;
        uint256[] videoIDs;
    }
    struct vault_info {
        address returnAddress;
        uint256 lockstart;
        uint256 lockduration;
        uint256 balance;
    }

    mapping (address => Subscription) sub_info;

    //uses video ID
    mapping(uint256 => vault_info) public vault;

    uint256 public treasury;

    event balance_update(address subscriber,uint256 new_balance);
    event treasury_withdrawal(address sender,address receiver,uint256 amount_withdrawn,uint256 treasury_balance);
    event vault_update(uint256 videoID, uint256 new_balance,uint256 new_lockstart ,uint256 new_lockend);
    event vault_creation(uint256 videoID, address returnAddress, uint256 balance, uint256 lockend, uint256 lockstart);
    event vault_cancellation(uint256 videoID);


    modifier onlyOwner {
        require(msg.sender == owner ,"caller is not owner");
        _; //given function runs here
    }
    modifier onlyAdmin {
        require(admin[msg.sender] || msg.sender == owner ,"caller does not have the perms required");
        _; //given function runs here
    }
    modifier onlyWhitelist {
        //if 0x0 is on the whitelist everyone is allowed through
        require( whitelist[0x0000000000000000000000000000000000000000] || whitelist[msg.sender] || admin[msg.sender] || msg.sender == owner,"caller is not on the whitelist");
        _; //given function runs here 
    }


    constructor(/*address _tokenAddress*/){
        owner = msg.sender;

        //tokenAddress = _tokenAddress;
        token = ERC20(tokenAddress);

        //hardcoded whitelist
            whitelist[msg.sender] = true;
            whitelist[0x7C213B11515bF087C277A219e2834E94a78403F7] = true;
    }


    //user functions
    //user functions
    //user functions
        function deposit(uint256 _amount) public onlyWhitelist{
            require(token.allowance(msg.sender, address(this)) >= _amount,"caller has not approved this contract to pull these funds");
            require(token.balanceOf(msg.sender) >= _amount,"caller does not have enough tokens in their wallet to pull");

            //transefer tokens from users wallet to this contract
            bool transfer_success = (token.transferFrom(msg.sender, address(this), _amount));
            require(transfer_success,"token transfer failed");

            //credit the tokens in their subscribtion
            sub_info[msg.sender].balance += _amount;

            emit balance_update(msg.sender,_amount);
        }

        function withdraw(uint256 _amount) external onlyWhitelist{
            Subscription memory _sub_info = sub_info[msg.sender];
            require(!(_amount > _sub_info.balance),"balance is smaller than withdraw amount");
            //remove tokens from users balance
            _sub_info.balance -= _amount;
            
            sub_info[msg.sender].balance = _sub_info.balance;

            //send tokens from this contract to users wallet
            bool transfer_success = (token.transfer(msg.sender, _amount));
            require(transfer_success,"token transfer failed");

            emit balance_update(msg.sender,_sub_info.balance);
        }
                                                            //exact lock start/end needs to be inputed not duration beacuse of tx execution times
        function lock_funds(uint256 videoID,uint256 time_till_lockstart/*in minutes*/, uint256 _lockduration/*in minutes*/,uint256 _amount/*ADD api_signiture*/) public onlyWhitelist{

            //require(vault[videoID].lockend == 0,"videoID is already in use, insert an unique ID");
            require(vault[videoID].returnAddress == address(0),"videoID is already in use, insert an unique ID");

            vault_info memory _vault;
            Subscription memory _sub_info = sub_info[msg.sender];

            require(_sub_info.balance >= _amount,"balance is smaller than the amount to be locked");

            _sub_info.balance -= _amount;
            _sub_info.lockedBalance += _amount;

            _vault.balance = _amount;
            _vault.returnAddress = msg.sender;

            _vault.lockstart = block.timestamp + (time_till_lockstart * 1 minutes);
            _vault.lockstart -= 7 minutes; //stream locks 7 minutes early for api

            _vault.lockduration = (_lockduration * 1 minutes);

            sub_info[msg.sender] = _sub_info;
            sub_info[msg.sender].videoIDs.push(videoID);
            vault[videoID] = _vault;

            emit balance_update(msg.sender,_sub_info.balance);
            emit vault_creation(videoID, msg.sender, _amount, lockend(videoID), _vault.lockstart);
        }

        /*
        function lock_additonal_funds (uint256 videoID,uint256 _amount, uint256 lock_extenstion/*in minutes) public onlyWhitelist {
            vault_info memory _vault = vault[videoID];

            require(_vault.returnAddress == msg.sender,"caller is not associated with this vault");
            require(_vault.lockstart > block.timestamp,"lock/stream has already begun");

            Subscription memory _sub_info = sub_info[msg.sender];

            require(_sub_info.balance >= _amount,"user balance is smaller than the amount to be locked");

            _sub_info.balance -= _amount;
            _sub_info.lockedBalance += _amount;
            _vault.balance += _amount;

            _vault.lockduration += (lock_extenstion * 1 minutes);

            sub_info[msg.sender] = _sub_info;
            vault[videoID] = _vault;

            emit balance_update(msg.sender, _sub_info.balance);            
            emit vault_update(videoID, _vault.balance, _vault.lockstart ,lockend(videoID));
        }

        function unlock_vault_funds(uint256 videoID, uint256 _amount, uint256 lock_reduction) public onlyWhitelist {
            vault_info memory _vault = vault[videoID];

            require(_vault.returnAddress == msg.sender,"caller is not associated with this vault");
            require(_vault.lockstart > block.timestamp,"lock/stream has already begun");

            Subscription memory _sub_info = sub_info[msg.sender];

            require(_vault.balance >= _amount,"vault balance is smaller than the amount to be locked");

            _sub_info.balance += _amount;
            _sub_info.lockedBalance -= _amount;
            _vault.balance -= _amount;

            _vault.lockduration -= (lock_reduction * 1 minutes);

            vault[videoID] = _vault;
            sub_info[msg.sender] = _sub_info;

            emit balance_update(msg.sender, _sub_info.balance);            
            emit vault_update(videoID, _vault.balance, _vault.lockstart ,lockend(videoID));
        }
        */
        
        function edit_vault(uint256 videoID, int256 _amount, int256 lock_duration_change /*in minutes*/, int256 lock_start_change/*in minutes*/) public onlyWhitelist {

            vault_info memory _vault = vault[videoID];

            require(_vault.returnAddress == msg.sender,"caller is not associated with this vault");
            require(_vault.lockstart > block.timestamp,"lock/stream has already begun");

            Subscription memory _sub_info = sub_info[msg.sender];

            require(int256(_sub_info.balance) >= _amount,"balance is smaller than the amount to be locked");
            
            //insuring that all the values stay above 0
            require(int256(_vault.balance) + _amount >= 0,"_amount + vault balance is smaller than 0");
            require(int256(_vault.lockstart) + (lock_start_change * 1 minutes) > int256(block.timestamp),"lock_start_change is too negitive");
            require(int256(_vault.lockduration) + (lock_duration_change * 1 minutes) > 0,"lock_duration_change is too negitive");

            _sub_info.balance = uint256(int256(_sub_info.balance) - _amount);
            _sub_info.lockedBalance = uint256(int256(_sub_info.lockedBalance) + _amount);

            _vault.balance = uint256(int256(_vault.balance) + _amount);

            _vault.lockstart = uint256(int256(_vault.lockstart) + (lock_start_change * 1 minutes));            
            _vault.lockduration = uint256(int256(_vault.lockduration) + (lock_duration_change * 1 minutes));

            sub_info[msg.sender] = _sub_info;
            vault[videoID] = _vault;

            emit balance_update(msg.sender, _sub_info.balance);            
            emit vault_update(videoID, _vault.balance, _vault.lockstart, lockend(videoID));
        }
         

        function cancel_stream (uint256 videoID) public onlyWhitelist {

            vault_info memory _vault = vault[videoID];

            require(_vault.returnAddress == msg.sender,"caller is not associated with this vault");
            require(_vault.lockstart > block.timestamp,"lock/stream has already begun");

            Subscription memory _sub_info = sub_info[msg.sender];

            _sub_info.lockedBalance -= _vault.balance;
            _sub_info.balance += _vault.balance;
            _vault.balance = 0;
            _vault.returnAddress = 0x1111111111111111111111111111111111111111;

            sub_info[msg.sender] = _sub_info;
            vault[videoID] = _vault;

            emit vault_cancellation(videoID);
            emit balance_update(msg.sender, _sub_info.balance);
        }

        function empty_unlocked_vault(uint256 vaultID) external onlyWhitelist{
            vault_info memory _vault = vault[vaultID];

            //require(_vault.returnAddress != address(0) || _vault.returnAddress != 0x1111111111111111111111111111111111111111,"vault does not exsist or was canceled") ADD
            require(_vault.balance > 0, "vault is empty");
            require(lockend(vaultID) < block.timestamp, "vault is not unlocked yet" );

            Subscription memory _sub_info = sub_info[_vault.returnAddress];

            _sub_info.lockedBalance -= _vault.balance;
            _sub_info.balance += _vault.balance;
            _vault.balance = 0;

            vault[vaultID] = _vault;
            sub_info[_vault.returnAddress] = _sub_info;

            emit balance_update(_vault.returnAddress,_sub_info.balance);
        }


    //admin functions
    //admin functions
    //admin functions
        function transfer_ownership(address new_owner) external onlyOwner{
            owner = new_owner;
        }

        function change_admin_status(address _admin, bool _status) external onlyOwner{
            admin[_admin] = _status;
        }

        function vaultWithdraw(uint256 videoID, uint256 _amount) public onlyAdmin{
            //local variable for gas optimizations 
            vault_info memory _vault = vault[videoID];
            require(_vault.returnAddress != address(0),"vault does not exist");
            require(_vault.balance >= _amount,"vault does not have enough funds to withdraw");
            Subscription memory _sub_info = sub_info[_vault.returnAddress];
            
            _sub_info.lockedBalance -= _vault.balance;
            _sub_info.balance += _vault.balance - _amount;
            _vault.balance = 0;


            //funds updated and ADDED to the treasury
            vault[videoID] = _vault;
            sub_info[_vault.returnAddress] = _sub_info;
            treasury += _amount;

            emit balance_update(_vault.returnAddress,_sub_info.balance);
        }
        
        function multiWithdraw (uint256[] calldata videoID,uint256[] calldata _amount) public onlyAdmin{
            require(videoID.length == _amount.length,"arrays must be of equal length");

            for(uint i = 0;i < _amount.length;){
                vaultWithdraw(videoID[i], _amount[i]);
                i++;
            }
        }

        //if 0x0000000000000000000000000000000000000000 is whitelisted everyone is whitelisted
        function add_to_whitelist(address[] calldata _address ,bool _status) external onlyAdmin {
            if (_address.length == 1){
                whitelist[_address[0]] = _status;
            }else {
                for(uint i=0;i<_address.length;i++){
                    whitelist[_address[i]] = _status;
                }
            }
        } 

        function treasuryWithdraw(address _receiver,uint256 _amount) public onlyAdmin {
            require(_amount <= treasury,"treasury dose not have enough funds to withdraw the requested amount");

            bool transfer_success = (token.transfer(_receiver, _amount));
            require(transfer_success,"token transfer failed");

            emit treasury_withdrawal(msg.sender,_receiver,_amount,treasury);
        }

    //view functions
    //view functions
    //view functions

        function lockend(uint256 vaultID) view internal returns (uint256 _lockend){
            return vault[vaultID].lockstart + vault[vaultID].lockduration;
        }
        function view_sub_info(address sub_owner) view external returns ( uint256 balance,uint256 lockedBalance,uint256[] memory vaultIDs) {

            return(
                sub_info[sub_owner].balance,
                sub_info[sub_owner].lockedBalance,
                sub_info[sub_owner].videoIDs
            );
        }

        //NEEDS CHNAGES
        function view_vault(uint256 videoID) view external returns ( address returnAddress,uint256 balance,uint256 _lockstart,uint256 _lockend,bool locked){
            _lockend = vault[videoID].lockstart + vault[videoID].lockduration;
            return (
                vault[videoID].returnAddress,
                vault[videoID].balance,
                vault[videoID].lockstart,
                _lockend,
                (vault[videoID].lockstart < block.timestamp && block.timestamp < _lockend )
            );
        }

        function view_blocktimestamp() view external returns (uint256 blocktimestamp) {
            return block.timestamp;
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