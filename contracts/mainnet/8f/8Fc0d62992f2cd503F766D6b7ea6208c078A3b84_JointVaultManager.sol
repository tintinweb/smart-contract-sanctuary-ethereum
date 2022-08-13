// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import "./interfaces/IVoterProxy.sol";
import "./interfaces/IBooster.sol";
import "./interfaces/IJointProxyVault.sol";
/*

*/
contract JointVaultManager{

    address public constant owner = address(0xa3C5A1e09150B75ff251c1a7815A07182c3de2FB);
    address public constant jointowner = address(0x8c2D06e11ca4414e00CdEa8f28633A2edAf79499);

    address public constant ownerProxy = address(0x59CFCD384746ec3035299D90782Be065e466800B);
    address public constant jointownerProxy = address(0xC0223fB0562555Bec938de5363D63EDd65102283);

    uint256 public ownerIncentive = 700;
    uint256 public jointownerIncentive = 700;
    uint256 public boosterIncentive = 300;
    uint256 public totalFees = 1700;

    uint256 public newOwnerIncentive = 700;
    uint256 public newJointownerIncentive = 700;
    uint256 public newBoosterIncentive = 300;
    address public feeProposedAddress;

    address public ownerFeeDeposit;
    address public jointownerFeeDeposit;

    uint256 public constant maxFees = 2000;
    uint256 public constant FEE_DENOMINATOR = 10000;


    mapping(address => bool) public allowedAddresses;
    mapping(address => bool) public allowedBooster;

    event ProposeFees(uint256 _owner, uint256 _jointowner, uint256 _booster, address _proposer);
    event AcceptFees(uint256 _owner, uint256 _jointowner, uint256 _booster, address _acknowledger);
    event AllowBooster(address _booster);
    event SetOwnerDeposit(address _depost);
    event SetJointownerDeposit(address _depost);
    event SetAllowedAddress(address _account, bool _allowed);
    event SetVeFXSProxy(address _vault, address _proxy);

    constructor() {
        //set current booster as allowed
        address currentBooster = IVoterProxy(ownerProxy).operator();
        allowedBooster[currentBooster] = true;

        //default owner deposit
        ownerFeeDeposit = address(0x8f55d7c21bDFf1A51AFAa60f3De7590222A3181e);
        //default jointowner deposit
        jointownerFeeDeposit = address(0x8c2D06e11ca4414e00CdEa8f28633A2edAf79499);
    }

    /////// Owner Section /////////

    modifier onlyOwner() {
        require(owner == msg.sender, "!auth");
        _;
    }

    modifier onlyJointOwner() {
        require(jointowner == msg.sender, "!auth");
        _;
    }

    modifier anyOwner() {
        require(owner == msg.sender || jointowner == msg.sender, "!auth");
        _;
    }


    //queue change to platform fees
    function setFees(uint256 _owner, uint256 _jointowner, uint256 _booster) external anyOwner{
        require(_owner + _jointowner + _booster <= maxFees, "fees over");

        feeProposedAddress = msg.sender;
        newOwnerIncentive = _owner;
        newJointownerIncentive = _jointowner;
        newBoosterIncentive = _booster;

        emit ProposeFees(_owner, _jointowner, _booster, msg.sender);
    }

    //accept proposed fees from the other owner
    function acceptFees() external anyOwner{
        require(msg.sender != feeProposedAddress, "fees over");
        
        totalFees = newOwnerIncentive + newJointownerIncentive + newBoosterIncentive;

        ownerIncentive = newOwnerIncentive;
        jointownerIncentive = newJointownerIncentive;
        boosterIncentive = newBoosterIncentive;

        emit AcceptFees(ownerIncentive, jointownerIncentive, boosterIncentive, msg.sender);
    }

    //set deposit address for owner
    function setDepositAddress(address _deposit) external onlyOwner{
        require(_deposit != address(0),"zero");
        ownerFeeDeposit = _deposit;

        emit SetOwnerDeposit(_deposit);
    }

    //set deposit address for joint owner
    function setJointOwnerDepositAddress(address _deposit) external onlyJointOwner{
        require(_deposit != address(0),"zero");
        jointownerFeeDeposit = _deposit;

        emit SetJointownerDeposit(_deposit);
    }

    //let joint owner acknowlege a new booster implementation
    function allowBooster() external onlyJointOwner{
        address currentBooster = IVoterProxy(ownerProxy).operator();
        allowedBooster[currentBooster] = true;

        emit AllowBooster(currentBooster);
    }

    //add address to list of addresses that are allowed to make a vault
    function setAllowedAddress(address _account, bool _allowed) external anyOwner{
        allowedAddresses[_account] = _allowed;

        emit SetAllowedAddress(_account, _allowed);
    }

    //get fee for owner
    function getOwnerFee(uint256 _amount, address _usingProxy) external view returns(uint256 _feeAmount, address _feeDeposit){
        _feeAmount = _amount * (ownerIncentive + (_usingProxy == ownerProxy ? boosterIncentive : 0) ) / FEE_DENOMINATOR;
        _feeDeposit = ownerFeeDeposit;
    }

    //get fee for joint owner
    function getJointownerFee(uint256 _amount, address _usingProxy) external view returns(uint256 _feeAmount, address _feeDeposit){
        _feeAmount = _amount * (jointownerIncentive + (_usingProxy == jointownerProxy ? boosterIncentive : 0) ) / FEE_DENOMINATOR;
        _feeDeposit = jointownerFeeDeposit;
    }

    function isAllowed(address _account) external view returns(bool){
        return allowedAddresses[_account];
    }

    function setVaultProxy(address _vault) external onlyJointOwner{
        address currentBooster = IVoterProxy(ownerProxy).operator();
        //can call if current booster not on a confirmed list
        //we want to use the booster function if possible to properly manage everything
        //but this gives joint owner a way to protect itself from unwanted changes to booster
        //(also allow to be called on accepted but shutdown boosters)
        require(!allowedBooster[currentBooster] || IBooster(currentBooster).isShutdown(), "!auth");

        //set proxy used on vault
        IJointProxyVault(_vault).jointSetVeFXSProxy(jointownerProxy);

        emit SetVeFXSProxy(_vault, jointownerProxy);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IVoterProxy{
    function operator() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IJointProxyVault {
    function jointSetVeFXSProxy(address _proxy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IBooster {
   function addPool(address _implementation, address _stakingAddress, address _stakingToken) external;
   function deactivatePool(uint256 _pid) external;
   function voteGaugeWeight(address _controller, address _gauge, uint256 _weight) external;
   function setDelegate(address _delegateContract, address _delegate, bytes32 _space) external;
   function owner() external returns(address);
   function rewardManager() external returns(address);
   function isShutdown() external returns(bool);
}