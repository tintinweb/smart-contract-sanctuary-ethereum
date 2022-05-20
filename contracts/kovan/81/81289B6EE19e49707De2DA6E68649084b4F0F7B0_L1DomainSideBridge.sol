//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ICrossDomainMessenger.sol";


/// @title L1DomainSideBridge Contract
/// @author Sherif Abdelmoatty
/// @notice This contract is to be deployed in the mainnet(kovan for testing)
contract L1DomainSideBridge {
    address constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;
    address constant public Proxy_OVM_L1CrossDomainMessenger = 0x4361d0F75A0186C05f971c566dC6bEa5957483fD;  //Source & Destintion side rollup(Optimism) l1messenger address 

    address public sourceSideAddress; //Source Side Contract Address
    address public destinationSideAddress; //Destintion Side Contract Address
    
    address public governance;
    
    /// @notice Constructior function
    /// @notice Intialize the contract initiale values
    constructor(){
        governance = msg.sender;   
    }
    /// @notice onlyGovernance modifier 
    /// @notice allow only the Governor to access
    modifier onlyGovernance {
        require(msg.sender == governance, "Governance: You are not the Governor!!!");
        _;
    }

    /// @notice onlyL2Contract modifier
    /// @notice only allows a message from l1DomainSideBridge contract through the L2CrossDomainMessenger bridge
    /// @notice to call the confirmTicketPayed function
    modifier onlyL2Contract() {
        require(
            msg.sender == address(Proxy_OVM_L1CrossDomainMessenger)
            && ICrossDomainMessenger(Proxy_OVM_L1CrossDomainMessenger).xDomainMessageSender() 
            == sourceSideAddress
        );
        _;
    }

    /// @notice setContractsAddresses function
    /// @notice is only called once by governor to set the Source and Destination side contracts address
    function setContractsAddresses(address _sourceSideAddress, address _destinationSideAddress) onlyGovernance public{
        // require(sourceSideAddress == address(0), "Contract Adresses can only be set Once !!!");
        sourceSideAddress = _sourceSideAddress;
        destinationSideAddress = _destinationSideAddress;
    }
    
    /// @notice sends new hash onions to the source side contrac
    /// @notice this function is rollup dependant - Optimism Kovan
    function declareNewHashOnionHeadToSource(bytes32 _hashOnion) external{
        ICrossDomainMessenger l1cdm = ICrossDomainMessenger(Proxy_OVM_L1CrossDomainMessenger);
        l1cdm.sendMessage(
            sourceSideAddress,
            abi.encodeWithSignature(
                "addNewKnownHashOnion(bytes32)",
                _hashOnion
            ),
            1000000 // use whatever gas limit you want
        );
    }
    /*
    function testMessage(string memory _hashOnion) public{
        emit Deb(_hashOnion);
    }*/
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/**
 * @title ICrossDomainMessenger - Optimism Rollup
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}