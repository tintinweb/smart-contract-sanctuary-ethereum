// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Short and Simple Ownable by 0xInuarashi
// Ownable follows EIP-173 compliant standard

abstract contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "onlyOwner not owner!"); _; }
    function transferOwnership(address new_) external onlyOwner {
        address _old = owner;
        owner = new_;
        emit OwnershipTransferred(_old, new_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "../access/Ownable.sol";

// Note: This contract is pending a optimization-rework

// Payable Governance Module by 0xInuarashi
// This abstract contract utilizes for loops in order to iterate things 
// in order to be modular.
// It is not the most gas-effective implementation. 
// We sacrified gas-effectiveness for Modularity instead.
abstract contract PayableGovernance is Ownable {
    // Special Access
    address public payableGovernanceSetter;

    constructor() payable { 
        payableGovernanceSetter = msg.sender; 
    }
    modifier onlyPayableGovernanceSetter {
        require(msg.sender == payableGovernanceSetter, 
                "PayableGovernance: Caller is not Setter!");
        _; 
    }
    function reouncePayableGovernancePermissions() public onlyPayableGovernanceSetter {
        payableGovernanceSetter = address(0x0); 
    }

    // Receivable Fallback
    event Received(address from, uint amount);
    receive() external payable { emit Received(msg.sender, msg.value); }

    // Required Variables
    address payable[] internal _payableGovernanceAddresses;
    uint256[] internal _payableGovernanceShares;    

    mapping(address => bool) public addressToEmergencyUnlocked;

    // Withdraw Functionality
    function _withdraw(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }

    // Governance Functions
    function setPayableGovernanceShareholders(address payable[] memory addresses_,
    uint256[] memory shares_) public onlyPayableGovernanceSetter {
        require(_payableGovernanceAddresses.length == 0 
                && _payableGovernanceShares.length == 0, 
                "Payable Governance already set! To set again, reset first!");
        require(addresses_.length == shares_.length, 
                "Address and Shares length mismatch!");

        uint256 _totalShares;
        
        for (uint256 i = 0; i < addresses_.length; i++) {
            _totalShares += shares_[i];
            _payableGovernanceAddresses.push(addresses_[i]);
            _payableGovernanceShares.push(shares_[i]);
        }

        require(_totalShares == 1000, 
                "Total Shares is not 1000!");
    }
    function resetPayableGovernanceShareholders() public onlyPayableGovernanceSetter {
        while (_payableGovernanceAddresses.length != 0) {
            _payableGovernanceAddresses.pop(); 
        }
        while (_payableGovernanceShares.length != 0) {
            _payableGovernanceShares.pop(); 
        }
    }

    // Governance View Functions
    function balance() public view returns (uint256) {
        return address(this).balance;
    }
    function payableGovernanceAddresses() public view 
    returns (address payable[] memory) {
        return _payableGovernanceAddresses;
    }
    function payableGovernanceShares() public view returns (uint256[] memory) {
        return _payableGovernanceShares;
    }

    // Withdraw Functions
    function withdrawEther() public onlyOwner {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 
                && _payableGovernanceShares.length > 0, 
                "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length 
                == _payableGovernanceShares.length, 
                "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;

        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; 
        }
    
        require(_totalPayableShares == 1000, 
                "Payable Governance Shares is not 1000!");
        
        // // now, we start the withdrawal process if all conditionals pass
        // store current balance in local memory
        uint256 _totalETH = address(this).balance; 

        // withdraw loop for payable governance
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            uint256 _ethToWithdraw = ((_totalETH * _payableGovernanceShares[i]) / 1000);
            _withdraw(_payableGovernanceAddresses[i], _ethToWithdraw);
        }
    }

    function viewWithdrawAmounts() public view returns (uint256[] memory) {
        // require that there has been payable governance set.
        require(_payableGovernanceAddresses.length > 0 
                && _payableGovernanceShares.length > 0, 
                "Payable governance not set yet!");
         // this should never happen
        require(_payableGovernanceAddresses.length 
                == _payableGovernanceShares.length, 
                "Payable governance length mismatch!");
        
        // now, we check that the governance shares equal to 1000.
        uint256 _totalPayableShares;

        for (uint256 i = 0; i < _payableGovernanceShares.length; i++) {
            _totalPayableShares += _payableGovernanceShares[i]; 
        }
    
        require(_totalPayableShares == 1000, 
                "Payable Governance Shares is not 1000!");
        
        // // now, we start the array creation process if all conditionals pass
        // store current balance in local memory and instantiate array for input
        uint256 _totalETH = address(this).balance; 
        uint256[] memory _withdrawals = new uint256[] 
            (_payableGovernanceAddresses.length + 2);

        // array creation loop for payable governance values 
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[i] = ( (_totalETH * _payableGovernanceShares[i]) / 1000 );
        }
        
        // push two last array spots as total eth and added eths of withdrawals
        _withdrawals[_payableGovernanceAddresses.length] = _totalETH;

        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            _withdrawals[_payableGovernanceAddresses.length + 1] += _withdrawals[i]; 
        }

        // return the final array data
        return _withdrawals;
    }

    // Shareholder Governance
    modifier onlyShareholder {
        bool _isShareholder;
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            if (msg.sender == _payableGovernanceAddresses[i]) {
                _isShareholder = true;
            }
        }
        require(_isShareholder, "You are not a shareholder!");
        _;
    }

    function unlockEmergencyFunctionsAsShareholder() public onlyShareholder {
        addressToEmergencyUnlocked[msg.sender] = true;
    }

    // Emergency Functions
    modifier onlyEmergency {
        for (uint256 i = 0; i < _payableGovernanceAddresses.length; i++) {
            require(addressToEmergencyUnlocked[_payableGovernanceAddresses[i]],
                "Emergency Functions are not unlocked!");
        }
        _;
    }

    function emergencyWithdrawEther() public onlyOwner onlyEmergency {
        _withdraw(payable(msg.sender), address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract MerkleAllowlist {
    
    mapping(uint256 => bytes32) internal _indexToAllowlistRoot;
    
    function _setAllowlistRoot(uint256 index_, bytes32 allowlistRoot_) internal virtual {
        _indexToAllowlistRoot[index_] = allowlistRoot_;
    }

    function isAllowlisted(uint256 index_, address address_, uint256 amount_,
    bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_, amount_));
        uint256 l = proof_.length;
        uint256 i; unchecked { do {
            _leaf = _leaf < proof_[i] ?
            keccak256(abi.encodePacked(_leaf, proof_[i])) :
            keccak256(abi.encodePacked(proof_[i], _leaf));
        } while (++i < l); }
        return _leaf == _indexToAllowlistRoot[index_];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/** 
    Waterfall Mint
    Author: 0xInuarashi
    Library: CypherMate

    In the waterfall mint, there are 3 time-conditions:

        1/ If the time hasn't started yet, the supply MUST be in-bounds.
        2/ If the time is in-bounds, the supply MUST not be above END.
        3/ If the time has ended, the waterfall has ENDED.

    In a waterfall mint, we have the following parameters:
    
        currentTokenId_: The current Token ID to be minted
        mintAmount_: The amount to be minted with incremental Token ID
        timeStart_: The unix timestamp to start the waterfall on a TIME TRIGGER
        timeEnd_: The unix timestamp to end all activity on the waterfall
        tokenIdStart_: The Token ID to start the waterfall on a TOKEN ID TRIGGER 
        tokenIdEnd_: The Token ID to end all activity the waterfall

    _checkWaterfallState throws an error due to require-statements when the conditions
    are not fulfilled.

    _returnWaterfallState does not throw and returns a boolean instead. This is useful
    for making your own custom errors OR returning states for front-end functions to use.

    BOTH should always result in the same state 
    (if require throws, _return should be false)
*/


abstract contract WaterfallMint {
    
    function _checkWaterfallState(uint256 currentTokenId_, uint256 mintAmount_, 
    uint256 timeStart_, uint256 timeEnd_,
    uint256 tokenIdStart_, uint256 tokenIdEnd_) internal virtual view {

        // If the time hasn't started yet, the supply must be in-bounds
        if (block.timestamp < timeStart_) {
            require(currentTokenId_ >= tokenIdStart_ &&
                    (currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1),
                    "_checkWaterfallState: State 1 conditions not met!");
        }

        // If the time is in-bounds, the supply must not be above end
        if (block.timestamp >= timeStart_ &&
            block.timestamp <= timeEnd_) {
            require((currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1),
                    "_checkWaterfallState: State 2 conditions not met!");
        }

        // If the time is above end, it's over!
        require(block.timestamp <= timeEnd_,
                "_checkWaterfallState: Waterfall has ended!");

    }

    function _returnWaterfallState(uint256 currentTokenId_, uint256 mintAmount_, 
    uint256 timeStart_, uint256 timeEnd_,
    uint256 tokenIdStart_, uint256 tokenIdEnd_) internal virtual view returns (bool) {

        // If the time hasn't started yet, the supply must be in-bounds
        if (block.timestamp < timeStart_) {
            if (currentTokenId_ >= tokenIdStart_ &&
                (currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1)) {
                return true;
            }
        }

        // If the time is in-bounds, the supply must not be above end
        if (block.timestamp >= timeStart_ &&
            block.timestamp <= timeEnd_) {
            if ((currentTokenId_ + mintAmount_) <= (tokenIdEnd_ + 1)) {
                return true;
            }
        }

        // the third require is not required here, because this function is 
        // false-by-default vs true-by-default of the require statement _check
        // function above, thus, if block.timestamp is > timeEnd_, it falls to false.
        // if it's < timeEnd_, its catched by the second if-block above assuming
        // already that it is within time-bounds., which is exactly the 
        // condition we need assuming block.timestamp is < timeEnd_.
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// EOAable adds a contract modifier to your contract
// that only allows EOAs to intract with functions using the
// msg.sender == tx.origin method

abstract contract OnlyEOA {
    modifier onlyEOA {
        require(msg.sender == tx.origin, "Only EOA!");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Import Solidity Modules
import {Ownable} from "cyphersuite/access/Ownable.sol";
import {OnlyEOA} from "cyphersuite/security/OnlyEOA.sol";
import {MerkleAllowlist} from "cyphersuite/sale/MerkleAllowlist.sol";
import {WaterfallMint} from "cyphersuite/sale/WaterfallMint.sol";
import {PayableGovernance} from 
    "cyphersuite/governance/PayableGovernance.sol";

// Interfaces 
interface iMachina {
    function totalSupply() external view returns (uint256);
    function nextTokenId() external view returns (uint256);
    function mintAsController(address to_, uint256 amount_) external;
}

contract MachinaSale is Ownable, OnlyEOA, MerkleAllowlist, 
WaterfallMint, PayableGovernance {

    ///// Interfaces /////
    iMachina public Machina;

    ///// Constraints /////
    uint256 public maxSupply;               // 7777
    uint256 public allowlistPrice;          // 0.0666 ether     || 66600000000000000
    uint256 public publicPrice;             // 0.0777 ether     || 77700000000000000

    ///// Times /////
    uint256 public waterfallStartTime;      // 1668781800
    uint256 public featherMintDuration;     // 30 minutes || 1800
    uint256 public machinaMintDuration;     // 3 hours || 10800

    ///// Configs /////
    bool public publicMintOpen;             // default: true

    ///// Proxy Initializer /////
    bool public proxyIsInitialized;

    function proxyInitialize(
        address newOwner_, 
        address machinaAddress_,
        uint256 maxSupply_, 
        uint256 allowlistPrice_, 
        uint256 publicPrice_,
        uint256 waterfallStartTime_, 
        uint256 featherMintDuration_, 
        uint256 machinaMintDuration_, 
        bool publicMintOpen_
    ) public {

        require(!proxyIsInitialized, "Proxy already initialized");
        proxyIsInitialized = true;

        // Hardcode
        owner = newOwner_; // Ownable.sol
        payableGovernanceSetter = newOwner_; // PayableGovernance.sol

        // Interface
        Machina = iMachina(machinaAddress_);

        // Sale Configs
        maxSupply = maxSupply_;
        allowlistPrice = allowlistPrice_;
        publicPrice = publicPrice_;

        waterfallStartTime = waterfallStartTime_;
        featherMintDuration = featherMintDuration_;
        machinaMintDuration = machinaMintDuration_;

        publicMintOpen = publicMintOpen_;
    }

    ///// Constructor (For Implementation) /////
    constructor() {
        proxyInitialize(
            msg.sender, 
            address(0), 
            0, 
            100_000_000 ether, 
            100_000_000 ether, 
            0, 
            0, 
            0, 
            false);
    }

    ///// Token Ranges /////
    uint256 public constant teamReserved = 400;
    uint256 public constant featherMintUpper = 1399;
    uint256 public constant machinaMintLower = 1000;

    ///// Ownable Configs /////
    function setMachina(address machina_) external onlyOwner {
        Machina = iMachina(machina_);
    }

    function setMaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function setAllowlistPrice(uint256 allowlistPrice_) external onlyOwner {
        allowlistPrice = allowlistPrice_;
    }
    function setPublicPrice(uint256 publicPrice_) external onlyOwner {
        publicPrice = publicPrice_;
    }

    function setWaterfallStartTime(uint256 time_) external onlyOwner {
        waterfallStartTime = time_;
    }
    function setFeatherMintDuration(uint256 duration_) external onlyOwner {
        featherMintDuration = duration_;
    }
    function setMachinaMintDuration(uint256 duration_) external onlyOwner {
        machinaMintDuration = duration_;
    }

    function setPublicMintState(bool bool_) external onlyOwner {
        publicMintOpen = bool_;
    }

    function setAllowlistRoot(uint256 index_, bytes32 allowlistRoot_) 
    external onlyOwner {
        _setAllowlistRoot(index_, allowlistRoot_);
    }

    ///// Ownable Functions (Mint) /////
    function ownerMint(address to_, uint256 amount_) external onlyOwner {
        require(maxSupply >= (totalSupply() + amount_),
                "ownerMint exceeds maxSupply");
            
        Machina.mintAsController(to_, amount_);
    }

    ///// Eligibility Checks /////
    function isFeatherMintActive(uint256 startId_, uint256 mintAmount_) public view
    returns (bool) {
        uint256 _featherMintStartTime   = waterfallStartTime;
        uint256 _featherMintEndTime     = waterfallStartTime + featherMintDuration;
        uint256 _featherMintStartId     = 402; // 401 Tokens must be minted to trigger
        uint256 _featherMintEndId       = featherMintUpper;
        
        // This function will always return a boolean.
        return _returnWaterfallState(startId_, mintAmount_, 
                                    _featherMintStartTime, _featherMintEndTime,
                                    _featherMintStartId, _featherMintEndId);
    }
    function isMachinaMintActive(uint256 startId_, uint256 mintAmount_) public view
    returns (bool) {
        uint256 _machinaMintStartTime   = waterfallStartTime + featherMintDuration;
        uint256 _machinaMintEndTime     = _machinaMintStartTime + machinaMintDuration;
        uint256 _machinaMintStartId     = machinaMintLower;
        uint256 _machinaMintEndId       = maxSupply;

        // This function will always return a boolean.
        return _returnWaterfallState(startId_, mintAmount_,
                                    _machinaMintStartTime, _machinaMintEndTime,
                                    _machinaMintStartId, _machinaMintEndId);
    }
    function isPublicMintActive() public view returns (bool) {
        uint256 _machinaMintEndTime = 
            waterfallStartTime + featherMintDuration + machinaMintDuration;
        if (block.timestamp > _machinaMintEndTime && publicMintOpen) return true;
        return false;
    }

    ///// View Helpers /////
    function nextTokenId() public view returns (uint256) {
        return Machina.nextTokenId();
    }
    function totalSupply() public view returns (uint256) {
        return Machina.totalSupply();
    }

    ///// Feather Mint /////
    mapping(address => uint32) public addressToFeatherMinted;

    function featherMint(uint256 mintAmount_, uint256 proofAmount_, 
    bytes32[] calldata proof_) external payable onlyEOA {

        // Grab the NextTokenId and do a waterfall-stage check
        uint256 _nextTokenId = nextTokenId();
        require(isFeatherMintActive(_nextTokenId, mintAmount_),
                "FeatherMint is not active!");

        // Do a allowlisted check with index[1]
        require(isAllowlisted(1, msg.sender, proofAmount_, proof_),
                "You are not featherlisted!");
        
        // Do a quota check. Here, we use a custom mapping.
        uint32 _mintedAmount = addressToFeatherMinted[msg.sender];
        require(proofAmount_ >= (_mintedAmount + mintAmount_),
                "Mint amout exceeds quota!");

        addressToFeatherMinted[msg.sender] += uint32(mintAmount_);
        
        // Check that the msg.sender is sending the correct value
        uint256 _totalPrice = mintAmount_ * allowlistPrice;
        require(msg.value == _totalPrice,
                "Invalid value sent!");
        
        // Mint the tokens to the user
        Machina.mintAsController(msg.sender, mintAmount_);
    }

    ///// Machina Mint /////
    mapping(address => uint32) public addressToMachinaMinted;

    function machinaMint(uint256 mintAmount_, uint256 proofAmount_, 
    bytes32[] calldata proof_) external payable onlyEOA {

        // Grab the NextTokenId to do a waterfall-stage check
        uint256 _nextTokenId = nextTokenId();
        require(isMachinaMintActive(_nextTokenId, mintAmount_),
                "MachinaMint is not active!");

        // Do a allowlisted check with index[2]
        require(isAllowlisted(2, msg.sender, proofAmount_, proof_),
                "You are not machinalisted!");
        
        // Do a quota check. Here, we use a custom mapping.
        uint32 _mintedAmount = addressToMachinaMinted[msg.sender];
        require(proofAmount_ >= (_mintedAmount + mintAmount_),
                "Mint amout exceeds quota!");

        addressToMachinaMinted[msg.sender] += uint32(mintAmount_);
        
        // Check that the msg.sender is sending the correct value
        uint256 _totalPrice = mintAmount_ * allowlistPrice;
        require(msg.value == _totalPrice,
                "Invalid value sent!");
        
        // Mint the tokens to the user
        Machina.mintAsController(msg.sender, mintAmount_);
    }

    ///// Public Mint /////
    uint256 public constant maxMintPerPublicTx = 10;

    function publicMint(uint256 mintAmount_) external payable onlyEOA {
        
        // Check that the Public Mint is active
        require(isPublicMintActive(), 
            "Public Mint is not active!");
        
        // Check that the mintAmount_ is within TX limits
        require(maxMintPerPublicTx >= mintAmount_,
            "Amount exceeds max mints per TX!");
        
        // Check that msg.sender is sending the correct value
        uint256 _totalPrice = mintAmount_ * publicPrice;
        require(msg.value == _totalPrice,
                "Invalid value sent!");
        
        // Mint the tokens to the user
        Machina.mintAsController(msg.sender, mintAmount_);
    }
}