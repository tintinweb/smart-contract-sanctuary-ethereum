// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract CallerAuthenticator is Ownable {

    string private _secret;
    event DidAuthenticationSucceed(bool success);
    event EncryptionCompleted(bytes32 s);

    constructor (string memory secret_) {
        _secret = secret_;
    }

    /*
    * Process authentication request and returns decrypted purcchase count
    * Returns: quantity
    * 0x122A207fC7211c979513De82e8bef3385c5CC5Ad
    */
    function processAuthentication(uint256 request_id, bytes32 message, address originAddress) public returns (uint256) {
        bool is_authenticated = verifyProofByte(message, originAddress);
        require(is_authenticated == true, "Not authenticated.");
        return getTokenID(request_id);
    }

    /*
    * Get token ID. Let's not publish this contract, so it can be simple trick like simple arithmetic 
    */
    function getTokenID(uint256 requestId) public pure returns (uint256) {
        return requestId % 87;
    }

    /*
    * Secret setting
    */
    function setSecret(string memory secret_) public onlyOwner {
        _secret = secret_;
    }

    /*
    * verify proof by comparing calculated proof and injected message
    */
    function verifyProofByte(bytes32 message, address originAddress) public returns (bool) {
        bool is_auth = message == calculateProof(originAddress);
        emit DidAuthenticationSucceed(is_auth);
        return is_auth;
    }

    /*
    * Calculate proof by sha256 encryption method
    */
    function calculateProof(address senderAddress) public returns (bytes32) {
        string memory stringRawSignature = _concatenate(_secret, _convert(senderAddress));
        bytes32 hashedSecret = sha256(abi.encodePacked(stringRawSignature));
        emit EncryptionCompleted(hashedSecret);
        return hashedSecret;
    }

    /*
    * Calculate proof by sha256 encryption method
    */
    function calculateProof2(address senderAddress) public returns (string memory, bytes memory, bytes32) {
        string memory stringRawSignature = _concatenate(_secret, _convert(senderAddress));
        bytes memory rawSig = abi.encode(stringRawSignature);
        bytes32 hashedSecret = sha256(rawSig);
        emit EncryptionCompleted(hashedSecret);
        return (stringRawSignature, rawSig, hashedSecret);
    }


    /*
    * Calculate proof by sha256 encryption method
    */
    function calculateProof3(address senderAddress) public returns (string memory, bytes memory, bytes32) {
        string memory stringRawSignature = _concatenate(_secret, _convert(senderAddress));
        bytes memory rawSig = bytes(stringRawSignature);
        bytes32 hashedSecret = sha256(rawSig);
        emit EncryptionCompleted(hashedSecret);
        return (stringRawSignature, rawSig, hashedSecret);
    }

    /*
    * Calculate proof by sha256 encryption method
    */
    function calculateProof4(address senderAddress) public returns (string memory, bytes memory, bytes32) {
        string memory stringRawSignature = _concatenate(_secret, _convert(senderAddress));
        bytes memory rawSig = abi.encodePacked(stringRawSignature);
        bytes32 hashedSecret = sha256(rawSig);
        emit EncryptionCompleted(hashedSecret);
        return (stringRawSignature, rawSig, hashedSecret);
    }

    /*
    * internal function to conver address to string
    */
    function _convert(address addr) public pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i = 0; i < 20; i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 * leftValue;

            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue + 48) : bytes1(leftValue + 87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue + 48) : bytes1(rightValue + 87);

            stringBytes[2 * i + 3] = rightChar;
            stringBytes[2 * i + 2] = leftChar;
        }

        return string(stringBytes);
    }

    /*
    * helpwe function to concatinate string on bytes
    */
    function _concatenate(string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
}