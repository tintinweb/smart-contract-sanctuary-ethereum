/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: No license

pragma solidity 0.8.16;

interface PaymentChannel {
    function openChannel(
        address channelId,
        uint256 forDuration,
        address ephemeralConsumerAddress) external payable returns (bool);
}

contract CrowdFunding {

    address public provider;
    uint256 public cap;
    uint256 public thresholdCap;
    uint256 public initialBlock;
    uint256 public timeToMarketBlocks;
    string public offerCode;
    mapping (address => uint256) public nonces;
    mapping (address => mapping (uint256 => uint256)) public orders;
    bool internal deployed;
    string public paymentContractType;
    address public paymentContractAddress;
    PaymentChannel internal pc;

    event OfferCreation (address indexed provider, string indexed offerCode);
    event ChannelOpened(
        address indexed consumer,
        address indexed channelId,
        uint256 indexed expiration,
        address ephemeralConsumerAddress
    );

    constructor (uint256 _cap,
                 uint256 _thresholdCap,
                 uint256 _timeToMarketBlocks,
                 string memory _offerCode,
                 string memory _paymentContractType) {
        provider = msg.sender;
        cap = _cap;
        thresholdCap = _thresholdCap;
        initialBlock = block.number;
        timeToMarketBlocks = _timeToMarketBlocks;
        offerCode = _offerCode;
        paymentContractType = _paymentContractType;
        emit OfferCreation(msg.sender, offerCode);
    }

    function postOrder () external payable {
        require(address(this).balance <= cap, "Demand beyond cap");
        nonces[msg.sender] = nonces[msg.sender] + 1;
        orders[msg.sender][nonces[msg.sender]] = msg.value;
    }

    function deleteOrder (uint256 nonce) external {
        require(orders[msg.sender][nonce] > 0, "Nonce already deleted");
        require(!deployed, "Resource has been deployed, cannot delete");
        require((block.number - initialBlock) > timeToMarketBlocks, "Not reached time to market yet");
        uint amountToWithdraw = orders[msg.sender][nonce];
        orders[msg.sender][nonce] = 0;
        nonces[msg.sender] = nonces[msg.sender] - 1;
        payable(msg.sender).transfer(amountToWithdraw);
    }

    function unlock (address newPaymentContractAddress) external {
        require(msg.sender == provider, "Only provider can unlock");
        require(newPaymentContractAddress != address(0), "Cannot unlock to null address");
        deployed = true;
        paymentContractAddress = newPaymentContractAddress;
        pc = PaymentChannel(paymentContractAddress);
    }

    function openChannel (uint256 nonce, address ephemeralAddress) external {
        require(deployed, "Resource has not been deployed, channel cannot be opened");
        require(orders[msg.sender][nonce] > 0, "Consumer without funds");
        require(ephemeralAddress != address(0), "Cannot open the chanel to a null address");
        uint256 fundsToTransfer = orders[msg.sender][nonce];
        orders[msg.sender][nonce] = 0;
        require(pc.openChannel{ value: fundsToTransfer }(ephemeralAddress, 1, ephemeralAddress), "Channel could not be opened");
        emit ChannelOpened(msg.sender,
                           ephemeralAddress,
                           1,
                           ephemeralAddress);
        /* (bool success, ) =  address(pc).call{ value: orders[msg.sender][nonce] }
        (abi.encodeWithSignature("openChannel(address,uint256,address)", "call openChannel",
                                  ephemeralAddress, 1, ephemeralAddress));
        if (!success) {
             revert();
        } */
    }

}