/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity 0.8.1;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// pragma solidity >=0.7.0;

contract Ownable {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
}

contract OwnableDemo is Ownable {
    uint256 sum = 0;
    uint256[] numbers;

    // Push number to array
    function addNumber(uint256 number) public {
        numbers.push(number);
    }

    // Read sum variable
    function getSum() public view returns (uint256) {
        return sum;
    }

    function calculateSum() public onlyOwner {
        sum = 0;
        for (uint256 i = 0; i < numbers.length; i++) sum += numbers[i];
    }
}

interface INFT {
    function mint(
        string memory _tokenURI,
        uint256 _tokenId,
        uint256 _price,
        uint256 royalty,
        address receiver
    ) external returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferNFT(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function _validate(uint256 _id) external;

    function getNFTPrice(uint256 tokenId) external view returns (uint256);

    function getRoyalty(uint256 tokenId) external view returns (uint256);

    function getOwnerAddress(uint256 tokenId) external view returns (address);

    function getTokenUrl(uint256 tokenId) external view returns (string memory);
}

contract BuyNFT is Ownable {
    address payable private admin;
    uint256 private commision;
    address payable public _contractOwner;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => bool) public listedMap;
    mapping(uint256 => uint256) public royalty;
    mapping(uint256 => address) public firstOwner;

    constructor(uint256 commision1, address payable admin1) {
        admin = admin1;
        commision = commision1;
    }

    struct signverification {
        string messageVerify;
        bytes signatureVerify;
    }
    mapping(address => signverification[]) private signToken;
    event Purchase(
        address indexed previousOwner,
        address indexed newOwner,
        uint256 price,
        uint256 nftID,
        string uri
    );

    function cancel(
        uint256 _id,
        string memory message,
        bytes memory _signature,
        address contractAddress
    ) public {
        INFT nfts = INFT(contractAddress);
        require(msg.sender == nfts.ownerOf(_id), "ownership not confirmed");
        signToken[msg.sender].push(signverification(message, _signature));
    }

    function makeOffer() public payable {
        require(true, "Failed to send money");
    }

    function acceptOffer(
        uint256 _id,
        string memory message,
        bytes memory _signature,
        address contractAddress,
        address receiver
    ) public payable {
        address signer = verifyString(message, _signature);
        for (uint256 i = 0; i < signToken[signer].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(signToken[signer][i].messageVerify)
                ) ==
                keccak256(abi.encodePacked(message)) &&
                keccak256(
                    abi.encodePacked(signToken[signer][i].signatureVerify)
                ) ==
                keccak256(abi.encodePacked(_signature))
            ) {
                require(false, "This NFT is not open for  sale");
            }
        }
        getTokenIdFromMsg(message);
        // require(
        //     asciiToInteger(keccak256(abi.encodePacked(getTokenIdFromMsg(message)))) <= block.timestamp,
        //     "Offer Expired"
        // );

        INFT nfts = INFT(contractAddress);

        require(receiver != nfts.ownerOf(_id), "Can not buy what you own");

        // require(
        //     signer == receiver,
        //     "signature mismatch / This is not Offer Creator."
        // );

        // require(
        //     msg.value >= nfts.getNFTPrice(_id),
        //     "Error, the amount is lower."
        // );

        nfts._validate(_id);

        address _previousOwner = nfts.ownerOf(_id);
        address _newOwner = receiver;

        _trade(_id, nfts.getNFTPrice(_id), nfts, _newOwner);

        emit Purchase(
            _previousOwner,
            _newOwner,
            nfts.getNFTPrice(_id),
            _id,
            nfts.getTokenUrl(_id)
        );
    }

    function buy(
        uint256 _id,
        string memory message,
        bytes memory _signature,
        address contractAddress,
        address payable receiver
    ) public payable {
        address signer = verifyString(message, _signature);
        for (uint256 i = 0; i < signToken[signer].length; i++) {
            if (
                keccak256(
                    abi.encodePacked(signToken[signer][i].messageVerify)
                ) ==
                keccak256(abi.encodePacked(message)) &&
                keccak256(
                    abi.encodePacked(signToken[signer][i].signatureVerify)
                ) ==
                keccak256(abi.encodePacked(_signature))
            ) {
                require(false, "This NFT is not open for  sale");
            }
        }
        getTokenIdFromMsg(message);
        // require(
        //     asciiToInteger(keccak256(abi.encodePacked(getTokenIdFromMsg(message)))) <= block.timestamp,
        //     "Sale Expired"
        // );

        INFT nfts = INFT(contractAddress);

        require(msg.sender != nfts.ownerOf(_id), "Can not buy what you own");

        require(
            signer == nfts.ownerOf(_id),
            "signature mismatch / This is not owner of NFT"
        );

        require(
            msg.value >= nfts.getNFTPrice(_id),
            "Error, the amount is lower"
        );

        nfts._validate(_id);

        address _previousOwner = nfts.ownerOf(_id);
        address _newOwner = receiver;

        _trade(_id, nfts.getNFTPrice(_id), nfts, _newOwner);

        if (msg.value > nfts.getNFTPrice(_id)) {
            receiver.transfer(msg.value - nfts.getNFTPrice(_id));
        }

        emit Purchase(
            _previousOwner,
            _newOwner,
            nfts.getNFTPrice(_id),
            _id,
            nfts.getTokenUrl(_id)
        );
    }

    function mintAndBuy(
        string memory _tokenURI,
        uint256 _tokenId,
        uint256 _price,
        uint256 royalty,
        string memory message,
        bytes memory _signature,
        address contractAddress,
        address payable receiver
    ) public payable {

        INFT nfts = INFT(contractAddress);
        nfts.mint(
        _tokenURI,
        _tokenId,
        _price,
        royalty,
        receiver);

        uint _id = _tokenId;

        require(
            msg.value >= nfts.getNFTPrice(_id),
            "Error, the amount is lower"
        );

        nfts._validate(_id);

        address _previousOwner = nfts.ownerOf(_id);
        address payable _newOwner = payable(msg.sender);

        _trade(_id, nfts.getNFTPrice(_id), nfts, _newOwner);

        if (msg.value > nfts.getNFTPrice(_id)) {
            _newOwner.transfer(msg.value - nfts.getNFTPrice(_id));
        }

        emit Purchase(
            _previousOwner,
            _newOwner,
            nfts.getNFTPrice(_id),
            _id,
            nfts.getTokenUrl(_id)
        );
    }

    function _trade(
        uint256 _id,
        uint256 price,
        INFT nfts,
        address receiver
    ) internal {
        address payable _buyer = payable(receiver);
        address payable _owner = payable(nfts.ownerOf(_id));
        nfts.transferNFT(_owner, _buyer, _id);
        uint256 _commissionValue = (price * commision) / 100;
        uint256 _ownerRoyaltyValue = (price * nfts.getRoyalty(_id)) / 100;
        uint256 _sellerValue = price - _commissionValue - _ownerRoyaltyValue;

        _owner.transfer(_sellerValue);
        admin.transfer(_commissionValue);
        payable(nfts.getOwnerAddress(_id)).transfer(_ownerRoyaltyValue);
    }

    function changeCommision(uint256 fees) public onlyOwner returns (bool) {
        require((25 > fees), "Commission percent is higher");
        commision = fees;
        return true;
    }

    function asciiToInteger(bytes32 x) public pure returns (uint256) {
    uint256 y;
    for (uint256 i = 0; i < 32; i++) {
        uint256 c = (uint256(x) >> (i * 8)) & 0xff;
        if (48 <= c && c <= 57)
            y += (c - 48) * 10 ** i;
        else
            break;
    }
    return y;
    }

    function changeAdminAddress(address payable _changeAdminAddress)
        public
        onlyOwner
        returns (bool)
    {
        require(_changeAdminAddress != address(0), "admin address is invalid");
        admin = _changeAdminAddress;
        return true;
    }

    function getAdminAddress() public view returns (address) {
        return admin;
    }

    function getPresentCommission() public view onlyOwner returns (uint256) {
        return commision;
    }

    function verifyString(string memory message, bytes memory _signature)
        public
        pure
        returns (address signer)
    {
        string memory header = "\x19Ethereum Signed Message:\n000000";

        uint256 lengthOffset;
        uint256 length;
        assembly {
            // The first word of a string is its length
            length := mload(message)
            // The beginning of the base-10 message length in the prefix
            lengthOffset := add(header, 57)
        }

        // Maximum length we support
        require(length <= 999999);

        // The length of the message's length in base-10
        uint256 lengthLength = 0;

        // The divisor to get the next left-most message length digit
        uint256 divisor = 100000;

        // Move one digit of the message length to the right at a time
        while (divisor != 0) {
            // The place value at the divisor
            uint256 digit = length / divisor;
            if (digit == 0) {
                // Skip leading zeros
                if (lengthLength == 0) {
                    divisor /= 10;
                    continue;
                }
            }

            // Found a non-zero digit or non-leading zero digit
            lengthLength++;

            // Remove this digit from the message length's current value
            length -= digit * divisor;

            // Shift our base-10 divisor over
            divisor /= 10;

            // Convert the digit to its ASCII representation (man ascii)
            digit += 0x30;
            // Move to the next character and write the digit
            lengthOffset++;

            assembly {
                mstore8(lengthOffset, digit)
            }
        }

        // The null string requires exactly 1 zero (unskip 1 leading 0)
        if (lengthLength == 0) {
            lengthLength = 1 + 0x19 + 1;
        } else {
            lengthLength += 1 + 0x19;
        }

        // Truncate the tailing zeros from the header
        assembly {
            mstore(header, lengthLength)
        }

        // Perform the elliptic curve recover operation
        bytes32 check = keccak256(abi.encodePacked(header, message));
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(check, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getTokenIdFromMsg(string memory name)
        internal
        view
        returns (string memory)
    {
        string memory tokenId;
        for (uint256 i = 0; i < bytes(name).length; i++) {
            if (
                keccak256(abi.encodePacked(bytes(name)[i])) ==
                keccak256(abi.encodePacked("!"))
            ) {
                for (uint256 j = i + 1; j < bytes(name).length; j++) {
                    tokenId = string(
                        abi.encodePacked(bytes(tokenId), bytes(name)[j])
                    );
                }
            }
        }
        return (tokenId);
    }
}