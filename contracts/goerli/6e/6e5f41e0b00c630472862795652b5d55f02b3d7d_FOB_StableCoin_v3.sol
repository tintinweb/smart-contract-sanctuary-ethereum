/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

library SafeMath {

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//      /////////////////////////// Definitions ///////////////////
contract FOB_StableCoin_v3 {
    //uint private constant PERCENTAGE_RATE = 100*(10**18) ;
    using SafeMath for uint;

    mapping (bytes32 => uint) public delivery_time;
    mapping (bytes32 => string) public pi_refrence;
    mapping (bytes32 => bytes32) public pi_hash;
    mapping (bytes32 => bytes32) public ci_hash;
    mapping (bytes32 => bytes32) public bl_hash;

    mapping (bytes32 => address) public buyer;
    mapping (bytes32 => address) public seller;
    mapping (bytes32 => address) public inspector;
    mapping (bytes32 => address) public forwarder;

    mapping (bytes32 => uint) seller_penalty;
    mapping (bytes32 => uint) platform_fee;
    mapping (bytes32 => uint) total_amount;
    mapping (bytes32 => uint) inspector_fee;
    mapping (bytes32 => uint) forwarder_fee;    

    mapping(address => uint) public depositors_balances;
    
    address public platform;

    IERC20 private Token;
    address private token_address;
    // string private token_symbol;
    uint private token_decimals;
    
    mapping (bytes32 => bool[11]) public StatesArray;
        // 0- contract_created
        // 1- buyer_payment_done
        // 2- seller_payment_done
        // 3- inspector_assigned
        // 4- forwarder_assigned
        // 5- forwarder_fee_paid 
        // 6- inspector_fee_paid
        // 7- inspection_done
        // 8- bl_issued
        // 9- done
        // 10- terminated

//      /////////////////////////// End of Definitions ///////////////////


//     ///////////////////////////   Modifiers  ///////////////////

    // modifier only_buyer(bytes32 _contractID) {
    //     require(msg.sender == buyer[_contractID],"Only Buyer can call this.");
    //     _;
    // }
    
    modifier only_platform() {
        require(msg.sender == platform,"Only Platform can call this.");
        _;
    }
    
    // modifier only_seller() {
    //     require(msg.sender == seller, "Only Seller can call this.");
    //     _;
    // }
      
    // modifier only_inspector() {
    //     require(msg.sender == inspector, "Only Inspector can call this.");
    //     _;
    // }

    // modifier only_forwarder() {
    //     require(msg.sender == forwarder, "Only Forwarder can call this.");
    //     _;
    // }

//      ///////////////////////////  End of  Modifiers  ///////////////////

//      ///////////////////////////  Functions (Write) ///////////////////

    constructor() {
        platform = msg.sender;
    }
    
    function initiate_contract (
        bytes32 _contractID,
        string memory _pi_refrence, 
        uint[4] memory _all_uints, 
        address _buyer, 
        address _seller, 
        bytes32 _pi_hash
    ) only_platform public {
        require(!StatesArray[_contractID][0], "Contract created before!");
        require(_seller         != address(0), "constructor: Invalid seller address!");
        require(_buyer          != address(0), "constructor: Invalid buyer address!");
        
        pi_refrence[_contractID]     = _pi_refrence;
        pi_hash[_contractID]         = _pi_hash;
        delivery_time[_contractID]   = _all_uints[3];

        seller_penalty[_contractID]  = _all_uints[0];
        total_amount[_contractID]    = _all_uints[1];
        platform_fee[_contractID]    = _all_uints[2];
        
        buyer[_contractID]           = _buyer;
        seller[_contractID]          = _seller;
        
        StatesArray[_contractID][0]  = true;
        
    }      

    function setToken(address _token_address, uint _token_decimals) public only_platform{
        Token           = IERC20(_token_address);
        token_decimals  = _token_decimals;
    } 
        
    function deposit_to_contract(bytes32 _contractID) public{
        require(StatesArray[_contractID][0], "Wrong state!");
        require(msg.sender == seller[_contractID] || msg.sender == buyer[_contractID], "Deposit_to_contract: Permission denied! Only Seller and Buyer can call this function.");
        uint seller_share = seller_penalty[_contractID].add(platform_fee[_contractID].div(2));
        uint buyer_share = total_amount[_contractID].add(platform_fee[_contractID].div(2));
        if(msg.sender == buyer[_contractID]) {
            require(Token.balanceOf(buyer[_contractID]) >= buyer_share, "Deposit_to_contract: Buyer Insufficient Funds!");
            require(Token.allowance(msg.sender, address(this))>=buyer_share, "Deposit_to_contract: Failed on transferFrom Buyer!(Allowance)");
            require(Token.transferFrom(msg.sender, address(this), buyer_share), "Deposit_to_contract: Failed on transferFrom Buyer!");
            require(Token.transfer(platform, platform_fee[_contractID].div(2)), "Deposit_to_contract: Token platform transfer failed!(buyer)");
            depositors_balances[msg.sender] = total_amount[_contractID] ;
            StatesArray[_contractID][1]=true;
        }
        else if(msg.sender == seller[_contractID]) {
            require(Token.balanceOf(seller[_contractID]) >= seller_share, "Deposit_to_contract: Seller Insufficient Funds!");
            require(Token.allowance(msg.sender, address(this))>=seller_share, "Deposit_to_contract: Failed on transferFrom Seller!(Alloance)");
            require(Token.transferFrom(msg.sender, address(this), seller_share), "Deposit_to_contract: Failed on transferFrom Seller!");
            require(Token.transfer(platform, platform_fee[_contractID].div(2)), "Deposit_to_contract: Token platform transfer failed!(seller)");
            depositors_balances[msg.sender] = seller_penalty[_contractID];
            StatesArray[_contractID][2]=true;
        }
    }

    function contract_finalization(bytes32 _contractID) public only_platform{
        require(StatesArray[_contractID][7],"Inspection not done yet!");
        require(StatesArray[_contractID][8],"Bill of Lading not yet issued!");
        if (Token.balanceOf(address(this)) >= total_amount[_contractID].add(seller_penalty[_contractID].add(inspector_fee[_contractID].add(forwarder_fee[_contractID])))){
            require(Token.transfer(seller[_contractID],total_amount[_contractID].add(seller_penalty[_contractID])),"Tranfer to Seller account failed!");
            require(Token.transfer(inspector[_contractID],inspector_fee[_contractID]),"Transfer to Inspector account failed!");
            require(Token.transfer(forwarder[_contractID],forwarder_fee[_contractID]),"Transfer to Forwarder account failed!");
            if (Token.balanceOf(address(this)) > 0){
                Token.transfer(platform,Token.balanceOf(address(this)));
            }
            if (address(this).balance > 0 ){
                payable(platform).transfer(address(this).balance);
            }
            StatesArray[_contractID][9]=true;
        } else {
            StatesArray[_contractID][9]=false;
        }
    }

    function inspector_fee_payment (bytes32 _contractID, uint _inspector_fee) public{
        require((msg.sender == seller[_contractID]), "Seller could pay inspector fee");
        require(StatesArray[_contractID][1] && StatesArray[_contractID][2],"Payment should be done first.");
        require(StatesArray[_contractID][3],"Inspector should be assinged before.");
        require(Token.balanceOf(seller[_contractID]) >= _inspector_fee, "Deposit_to_contract: Seller Insufficient Funds!");
        require(Token.allowance(msg.sender, address(this))>= _inspector_fee, "Deposit_to_contract: Failed on transferFrom Seller!(Alloance)");
        require(Token.transferFrom(msg.sender, address(this), _inspector_fee), "Deposit_to_contract: Failed on transferFrom Seller!");
        depositors_balances [msg.sender] +=_inspector_fee;
        inspector_fee[_contractID] = _inspector_fee;
        StatesArray[_contractID][6]=true;
    }

    function assigning_inspector (bytes32 _contractID, address _inspector) public {
        require((msg.sender == seller[_contractID]), "Seller could assign inspector");
        require(StatesArray[_contractID][1] && StatesArray[_contractID][2],"Payment should be done first.");
        require((inspector[_contractID] == address(0)), "Inspector is not empty");
        inspector[_contractID] = _inspector;
        StatesArray[_contractID][3]=true;
    }

    function forwarder_fee_payment (bytes32 _contractID, uint _forwarder_fee) public{
        require((msg.sender == buyer[_contractID]), "Buyer could pay forwarder fee");
        require(StatesArray[_contractID][1] && StatesArray[_contractID][2],"Payment should be done first.");
        require(StatesArray[_contractID][4],"Forwarder should be assinged before.");
        require(Token.balanceOf(buyer[_contractID]) >= _forwarder_fee, "Deposit_to_contract: Buyer Insufficient Funds!");
        require(Token.allowance(msg.sender, address(this))>= _forwarder_fee, "Deposit_to_contract: Failed on transferFrom Buyer!(Alloance)");
        require(Token.transferFrom(msg.sender, address(this), _forwarder_fee), "Deposit_to_contract: Failed on transferFrom Buyer!");
        depositors_balances [msg.sender] +=_forwarder_fee;
        forwarder_fee[_contractID] = _forwarder_fee;
        StatesArray[_contractID][5]=true;
    }

    function assigning_forwarder (bytes32 _contractID, address _forwarder) public{
        require((msg.sender == buyer[_contractID]), "Seller could assign inspector");
        require(StatesArray[_contractID][1] && StatesArray[_contractID][2],"Payment should be done first.");
        require((forwarder[_contractID] == address(0)), "Forwarder is not empty");
        forwarder[_contractID] = _forwarder;
        StatesArray[_contractID][4]=true;
    }

    function inspector_submit_ci (bytes32 _contractID, bytes32 _ci_hash) public {
        require(msg.sender == inspector[_contractID], "Only inspector could submit CI");
        require(StatesArray[_contractID][6],"Inspection fee not paid.");
        require(ci_hash[_contractID].length == 0, "CI submitted before.");
        ci_hash[_contractID] = _ci_hash;
        StatesArray[_contractID][7]=true;
    }

    function forwarder_submit_bl (bytes32 _contractID, bytes32 _bl_hash) public{
        require(msg.sender == forwarder[_contractID],"Only forwarder could submit BL");
        require(StatesArray[_contractID][5],"Forwarding fee not paid.");
        require(bl_hash[_contractID].length == 0, "BL submitted before.");
        bl_hash[_contractID] = _bl_hash;
        StatesArray[_contractID][8]=true;
    }
//      ///////////////////////////  End of Functions (write) ///////////////////

/////////////////String Library/////////////////////////////

/////////////////String Library/////////////////////////////

    //  prevent implicit acceptance of ether 
    receive() external payable {
         revert();
    }
}