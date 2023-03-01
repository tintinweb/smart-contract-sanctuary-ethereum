// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*
1.It should be an Upgradeable Smart Contract with ERC-1967 Transparent Upgradeable Proxy Pattern.

2.The smart contract should be capable of creating new channels from the contract itself, 
using the Push Core Contract on Goerli Testnet.

3. And lastly, the smart contract should also include a feature to 
emit out on-chain notifications using Push Communicator Contract on the Goerli testnet. */

interface IERC20{
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

interface IPUSHCore {
    enum ChannelType {
        ProtocolNonInterest,
        ProtocolPromotion,
        InterestBearingOpen,
        InterestBearingMutual,
        TimeBound,
        TokenGaited
    }

    function createChannelWithPUSH(
        ChannelType _channelType,
        bytes calldata _identity,
        uint256 _amount,
        uint256 _channelExpiryTime
    ) external;
}

interface IPUSHCommInterface {
    function sendNotification(
        address _channel,
        address _recipient,
        bytes calldata _identity
    ) external;
}

contract Push {
    IERC20 PUSH  ;
    IPUSHCore Core ;
    IPUSHCommInterface Comm ;
    bytes identity ;
    uint256 amount ;


    function initializer() external{
             PUSH = IERC20(0x2b9bE9259a4F5Ba6344c1b1c07911539642a2D33);
     Core = IPUSHCore(0xd4E3ceC407cD36d9e3767cD189ccCaFBF549202C);
     Comm =
        IPUSHCommInterface(0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa);
     identity =
        "0x312b516d5962773557707072426e687a66615559336d753271474d7632746f324448785734646f356174794a58475a6b";
     amount = 50 * 10**18;
    }

    function createChannel() external {
            PUSH.approve(address(Core),50* 10**18);

        //Approve the core contract for PUSH tokens before calling
        Core.createChannelWithPUSH(
            IPUSHCore.ChannelType.InterestBearingOpen,
            identity,
            amount,
            0
        );
    }

    function sendNotif(address channel, string memory _notif) external {
        IPUSHCommInterface(Comm).sendNotification(
            channel,
            address(this), 
            bytes(
                string(
                    abi.encodePacked(
                        "0", 
                        "+", 
                        "3", 
                        "+", 
                        "Testing Push", 
                        "+", 
                        _notif 
                    )
                )
            )
        );
    }
}