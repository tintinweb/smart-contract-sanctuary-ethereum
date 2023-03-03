/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

//EPNS Core Contract Interface
interface IPUSHCoreInterface {
   enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual,
        TimeBound,
        TokenGaited
    }

    function createChannelWithFees(
        ChannelType _channelType,
        bytes calldata _identity,
        uint256 _amount
    )external;


}

// PUSH Comm Contract Interface
interface IPUSHCommInterface {
    function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

//ERC20 Interface to approve sending Push
interface IERC20Interface {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Fund {
    address public EPNS_CORE_ADDRESS;
    address public EPNS_COMM_ADDRESS;
    address public PUSH_ADDRESS;
    address  payable public owner;
    bool private initialized;

    function initialize() public {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
       owner = payable(msg.sender);
       EPNS_CORE_ADDRESS = 0xd4E3ceC407cD36d9e3767cD189ccCaFBF549202C;
       EPNS_COMM_ADDRESS= 0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;
       PUSH_ADDRESS = 0x2b9bE9259a4F5Ba6344c1b1c07911539642a2D33;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform the task");
        _;
    }
  
    //To create channel
    function createChannelWithPUSH(string memory _ipfsHash) public onlyOwner {
        IERC20Interface(PUSH_ADDRESS).approve(EPNS_CORE_ADDRESS, 50);
        IPUSHCoreInterface(EPNS_CORE_ADDRESS).createChannelWithFees(
            IPUSHCoreInterface.ChannelType.InterestBearingOpen,
            bytes(string(
            abi.encodePacked(
                "2",
                "+",
                _ipfsHash
            )
        )),
            50
        );
    }

    // To send notification when the contract receives fund
     receive() external payable {
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            address(this), // from channel - recommended to set channel via dApp and put it's value -> then once contract is deployed, go back and add the contract address as delegate for your channel
            address(this), // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
            bytes(
                string(
                    // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                    abi.encodePacked(
                        "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                        "+", // segregator
                        "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                        "+", // segregator
                        "Title", // this is notificaiton title
                        "+", // segregator
                        "Body" // notification body
                    )
                )
            )
        );
    }

    function sendNotificationWithPUSH() public {
        IPUSHCommInterface(EPNS_COMM_ADDRESS).sendNotification(
            address(this), // from channel - recommended to set channel via dApp and put it's value -> then once contract is deployed, go back and add the contract address as delegate for your channel
            address(this), // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
            bytes(
                string(
                    // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                    abi.encodePacked(
                        "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
                        "+", // segregator
                        "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targetted or subset)
                        "+", // segregator
                        "Title", // this is notificaiton title
                        "+", // segregator
                        "Body" // notification body
                    )
                )
            )
        );
    }
    
        
    
    function transferFundToOwner() public payable onlyOwner{
        owner.transfer(address(this).balance);
    }
    
    function checkAmount() public view returns(uint){
        return address(this).balance;
    }
}