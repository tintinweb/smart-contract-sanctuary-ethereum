// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAnycallExecutor {
    function context() external returns (address from, uint256 fromChainID, uint256 nonce);
}


interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID,
        uint256 _flags

    ) external;

    function executor() external view returns (address);
}

  

contract AnycallFallback{

    // The Multichain anycall contract on bnb mainnet
    address public anyCallContract;


    address public ownerAddress;

    // Destination contract on Polygon
    address private peerAddress;

    uint private destChainId;
    
    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "only owner can call this method");
        _;
    }

    event NewMsg(string msg);
    
    constructor (
        address _anyCallContract,
        uint _destChainId
    ){
        destChainId = _destChainId;
        anyCallContract = _anyCallContract;
        ownerAddress = msg.sender;
    }

    function changeReceiverContract(address newReceiver) external onlyOwner {
        peerAddress=newReceiver;

    }


    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);

        bytes memory data = abi.encodeWithSelector(
            this.anyExecute.selector,
            _msg
        );


        if (msg.sender == ownerAddress){
        CallProxy(anyCallContract).anyCall(
            peerAddress,

            // sending the encoded bytes of the string msg and decode on the destination chain
            data,

            // 0x as fallback address because we don't have a fallback function
            address(this),

            // chainid of polygon
            destChainId,

            // Using 0 flag to pay fee on destination chain
            0
            );
            
        }

    }

    function compareStrings(string memory a, string memory b) public pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function anyExecute(bytes calldata data)
        external
        
        returns (bool success, bytes memory result)
    {
        bytes4 selector = bytes4(data[:4]);
        if (selector == this.anyExecute.selector) {
            (
                string memory message
            ) = abi.decode(
                data[4:],
                (string)
            );

            if (compareStrings(message,"fail")){
                return (false, "fail on purpose");
            }

            emit NewMsg(message);
        } else if (selector == this.anyFallback.selector) {

            // original data with selector would be passed here if thats the case
            (address _to, bytes memory _data) = abi.decode(data[4:], (address, bytes));
            this.anyFallback(_to, _data);
        } else {
            return (false, "unknown selector");
        }
        return (true, "");
    }

    event FallbackMsg(string msg);

    function anyFallback(address to, bytes calldata data) external {
        require(msg.sender == address(this), "AnycallClient: Must call from within this contract");
        require(bytes4(data[:4]) == this.anyExecute.selector, "AnycallClient: wrong fallback data");

        address executor = CallProxy(anyCallContract).executor();
        (address _from,,) = IAnycallExecutor(executor).context();
        require(_from == address(this), "AnycallClient: wrong context");

        (
            string memory message
        ) = abi.decode(
            data[4:],
            (string)
        );

        require(peerAddress == to, "AnycallClient: mismatch dest client");

        emit FallbackMsg(message);
    }

}