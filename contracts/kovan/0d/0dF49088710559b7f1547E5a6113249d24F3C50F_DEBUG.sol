pragma solidity 0.8.0;

contract DEBUG
{

    event EncodedKeccak(bytes32 something);
    event EncodedBytes(bytes something);

    uint256 public number;
    bytes encoding;
    bytes32 keccak;

    function EmitEncoding(string calldata _string) public {
        encoding = abi.encodePacked(_string);
        number = 1;
        emit EncodedBytes(encoding);
    }

    function EmitKeccak(bytes calldata _encoding) public {
        keccak = keccak256(_encoding);
        number = 2;
        emit EncodedKeccak(keccak);
    }

}