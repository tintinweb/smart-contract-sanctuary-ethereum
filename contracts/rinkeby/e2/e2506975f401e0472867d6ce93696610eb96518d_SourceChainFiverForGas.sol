/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: FiverForGasV2.sol


pragma solidity ^0.8.7;


// testnetbsc Anycall:https://testnet.bscscan.com/address/0x07f4521c480b4179c7abb30ff6d2f31b4e881b43
//testnet matic anycall:https://mumbai.polygonscan.com/address/0x4d5bacfef33fb9624af10c2d5658b6cf272be09f


//deployed here 0xD2954bAf65B36827EB32Bae3dDf20982f6390A9A

// 0407 deployed here 0x0b9d284f411aa8997c1e8286675e0ba2f6a5a4b3 bsctest
// 0407 rinkeby 0x0b28fe5925a3402f4bF2A4e1F834098FE90C536E
interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID
    ) external;
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: NATIVE_TRANSFER_FAILED');


    }
}


contract SourceChainFiverForGas {
    // chainlink pricefeed
    AggregatorV3Interface internal priceFeed;

    address public owner;
    // mapping(uint=>address) public chainidToLinkFeed;
    address public gasTokenLinkFeed;
    mapping(uint=>address) public chainidToDestContract;
    address public anycallContract;
    address public stableCoinAddress;
    /**
     * Network: Kovan
     * Aggregator: ETH/USD
     * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
     */



    //rinkby testnet 0xf8a363Cf116b6B633faEDF66848ED52895CE703b
    constructor(address _stableCoinAddress,address _anycallAddress,address _gasTokenLinkFeed) {
        // priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
        owner = msg.sender;
        gasTokenLinkFeed=_gasTokenLinkFeed;
        stableCoinAddress=_stableCoinAddress;
            //dai testnetbsc 0x8a9424745056Eb399FD19a0EC26A14316684e274 
    // dai testnet rinkeby 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735
        // 0x8a9424745056Eb399FD19a0EC26A14316684e274,0x1FF2e90F22dA39d5cB5748AB786C5AD6D9eBa440,0x07F4521C480B4179C7abB30FF6D2F31B4e881b43
        // 0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735,0xf8a363Cf116b6B633faEDF66848ED52895CE703b,0x8A753747A1Fa494EC906cE90E9f37563A8AF630e


        //official anycall testnet bsc 0x1FF2e90F22dA39d5cB5748AB786C5AD6D9eBa440
        //official anycall testnet eth 0xf8a363Cf116b6B633faEDF66848ED52895CE703b
//         Bnb on bnb testnet link feed:0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526

// ETH ON ETH rinkeby link feed:0x8A753747A1Fa494EC906cE90E9f37563A8AF630e 


        anycallContract=_anycallAddress;
        // chainidToDestContract[137]=0x122c6462A9fd99098c81Ea29Cf62e1766468671d;
    }
    receive() external payable {}

    fallback() external payable {}
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }
    /**
     * Returns the latest price
     */

    function updateGasTokenLinkFeed(address _gasTokenLinkFeed) onlyOwner external{
        gasTokenLinkFeed=_gasTokenLinkFeed;

    }

    function updateAnycallAddress(address _anycallAddress) onlyOwner external{
        anycallContract=_anycallAddress;
    }




    //what contract sends ether in other chains
    function updateChainidToDestContract(uint _chainid, address _shooterContract) onlyOwner external{
        chainidToDestContract[_chainid]=_shooterContract;

    }

    function getLatestGasNativePrice() public view returns (int) {


        (   
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(gasTokenLinkFeed).latestRoundData();
        return price;
    }


    function howMuchGasCanIGetForFiverThisChain() public view returns (uint) {

        uint fiver=5 ether;
        uint _linkFeedDecimals=AggregatorV3Interface(gasTokenLinkFeed).decimals();
        
        (   
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(gasTokenLinkFeed).latestRoundData();
        
        uint power=10**(18-_linkFeedDecimals);
        uint paddedPrice=uint(price)*power;
        uint gasTokenGot=(fiver*1 ether)/paddedPrice;
        return gasTokenGot;
    }


    //50%fee
    function howMuchGasCanIGetForFiverWithFeesThisChain() public view returns (uint) {

         uint fiver=5 ether;
        uint _linkFeedDecimals=AggregatorV3Interface(gasTokenLinkFeed).decimals();
        
        (   
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = AggregatorV3Interface(gasTokenLinkFeed).latestRoundData();
        
        uint power=10**(18-_linkFeedDecimals);
        uint paddedPrice=uint(price)*power;
        uint gasTokenGot=(fiver*1 ether)/paddedPrice;
        return gasTokenGot/2;
    }

    //test tx https://testnet.bscscan.com/tx/0xa9e9f121836cbb8d7b8b306237a6b5b621cd4e59f4b73a783b0b0a40d361e96f#eventlog

    event FiverForGasEvent(uint[] indexed toChainIds, address indexed receiver);

    function FiverForGas(uint[] calldata toChainIds,address receiver) public returns (uint [] memory) {

        uint[] memory gasTokenAmount = new uint[](toChainIds.length);
        // uint daiAmount=(5 ether)*toChainIds.length;
        uint fiver=5 ether;

        for (uint i=0; i<toChainIds.length; i++) {

            require(chainidToDestContract[toChainIds[i]]!=address(0x0),"unsupported chain");
            TransferHelper.safeTransferFrom(stableCoinAddress,msg.sender,address(this),fiver);
            
            
            CallProxy(anycallContract).anyCall(
            chainidToDestContract[toChainIds[i]],
            abi.encodeWithSignature("sendFiverrGasTokenViaCallAnyCall(address,address)"
            ,msg.sender,receiver),
            address(this),
            toChainIds[i]
            );
            
        }
        
        emit FiverForGasEvent(toChainIds,receiver);
        return gasTokenAmount;
    }

    function withdrawStables(address payable _to,uint _amount) onlyOwner external{
        TransferHelper.safeTransfer(stableCoinAddress,_to,_amount);
    }


    //For sending ether
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier onlyAnyCall() {
        require(msg.sender == anycallContract, "Not anycallAddress");
        _;
    }

    event sendFiverrGasTokenEvent(address indexed _chainAsender,address indexed _to,uint indexed gasTokenSent);
    function sendFiverrGasTokenViaCallAnyCall(address _from,address payable _to) onlyAnyCall public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        // bytes memory data
        uint FiverrGasToken=howMuchGasCanIGetForFiverWithFeesThisChain();
        (bool sent, ) = _to.call{value: FiverrGasToken}("");
        require(sent, "Failed to send Ether");

        emit sendFiverrGasTokenEvent(_from,_to,FiverrGasToken);
        // if failed do a callback to refund source chain
    }

    event Refund5Dai(address indexed failedContract,address indexed refundReceiver);
    //This is called on chain A if execution on chain B failed, refund the 5 dai to sender
    function anyFallback(address _chainbContract,bytes calldata _originalData) onlyAnyCall public {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        // bytes memory data
        
        //decode the original sendfrom address to get refund address
        (address _from,) = abi.decode(_originalData[4:], (address, address));
        uint fiver=5 ether;

        //refund 5 dai
        TransferHelper.safeTransfer(stableCoinAddress,_from,fiver);
        emit Refund5Dai(_chainbContract,_from);
        // if failed do a callback to refund source chain
    }



    function sendEtherViaCall(address payable _to,uint _amount) onlyOwner public payable {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        // bytes memory data
        (bool sent, ) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
        // if failed do a callback to refund source chain
    }

}