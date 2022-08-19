/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// File: contracts/UpointSeaman.sol


pragma solidity ^0.8.7;

/**
 * UpointSeaman.sol
 *
 * Rewards to Seaman
 * 
 * You use invitecode to mint success, you will get 100 Upoints.
 * Your friends use your invitecode to mint success, you will get 100 * mintedNum Upoints.
 *
 * set role => UpointFaucet.superOperators
 */

struct InvitationRecord {
        uint256 NumMinted;    // 
        uint256 NumAssisted;  // 
        uint256 NumInvited;   // 
        uint256 NumSecondaryInvited; // 
        uint256 ProfitAmount; // 
        address InvitedBy;    // 
}

interface UpointFaucet {
    function availableDrips() external view returns (uint256 upointDrips);
    function drip(address to, uint256 amount) external returns (bool success);
}

interface SeamanMinter {
    function invitationRecord(address one) external view returns (InvitationRecord memory);
}

contract UpointSeaman {

    UpointFaucet private _upointFaucet; 
    SeamanMinter private _seamanMinter;

    // claimed upoints
    mapping(address => uint256) private claimUpoints;

    address private owner;

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    event claimed(address indexed wallet, uint256 indexed val);

    /**
     * 
     *
     * UpointFaucet 
     */
    constructor(address upointFaucetConstract, address seamanMinterContract) {
       _upointFaucet = UpointFaucet(upointFaucetConstract);
       _seamanMinter = SeamanMinter(seamanMinterContract);
       owner = msg.sender;
       superOperators[msg.sender] = true;
    }

    function claim() public {
        uint256 amount = earnedUpoints(msg.sender);
        require(amount > 0, "Your earned upoints is zero");
        //require(earnUpoints(msg.sender) >= amount, "Your earn upoints must lager than your claim amount");
        uint256 upointDrips = _upointFaucet.availableDrips();
        require(upointDrips >= amount, "Upoint is not enough");

        claimUpoints[msg.sender] = claimUpoints[msg.sender] + amount;
        _upointFaucet.drip(msg.sender, amount);
        emit claimed(msg.sender, amount);
    }

    function earnedUpoints(address one) public view returns (uint256 upoints) {
        InvitationRecord memory record = _seamanMinter.invitationRecord(one);
        if(record.NumMinted < 1 && record.NumAssisted  < 1){
            return(0);
        }
        
        uint256 assistedUpoints = record.NumAssisted * 100; 
        
        uint256 mintedUpoints = 0;
        if(record.NumMinted > 0){
            mintedUpoints = 100;
        }
        uint256 gotUpoints = assistedUpoints + mintedUpoints;
                
        uint256 myClaimedUpoints = claimUpoints[one];

        upoints = gotUpoints - myClaimedUpoints;
        if( upoints < 0 ){
            upoints = 0;
        }
    }

    function claimedUpoints(address one) external view returns (uint256 upoints) {
        upoints = claimUpoints[one];
    }

    /// ---- config ------
    function seamanMinterAddress() external view returns(address) {
        return address(_seamanMinter);
    }

    function upointFaucetAddress() external view returns(address) {
        return address(_upointFaucet);
    }

    /// @notice Allows super operator to set
    function setSeamanMinterAddress(address seamanMinterContract) external isSuperOperator {
       _seamanMinter = SeamanMinter(seamanMinterContract);
    }

    /// @notice Allows super operator to set
    function setUpointFaucetAddress(address upointFaucetConstract) external isSuperOperator {
       _upointFaucet = UpointFaucet(upointFaucetConstract);
    }

    /// @notice Allows receiving ETH
    receive() external payable {
        payable(owner).transfer(msg.value);
    }

}