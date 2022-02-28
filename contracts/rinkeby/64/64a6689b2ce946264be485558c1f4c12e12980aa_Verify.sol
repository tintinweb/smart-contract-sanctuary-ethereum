pragma solidity ^0.8.12;
import "./ECDSA.sol";
import "./Strings.sol";

contract Verify{
    using ECDSA for bytes32;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 private constant PRESALE_TYPEHASH =
        keccak256("presale(address buyer,uint256 limit)");

    bytes32 private constant FREEMINT_TYPEHASH =
        keccak256("freeMint(address buyer,uint256 limit)");
        
    string public domainName;
    uint256 public version;
    uint256 public chainId;
    address public verifyingContract;
    address public whitelistSigner;

    event GotSignerAndExpectedSigner(address signer, address whitelistSigner);

    constructor(){
        DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("CryptoQueenz")),
        keccak256(bytes("1")),
        chainId,
        verifyingContract
      )
    );

    whitelistSigner = 0xc0A0aEa4f8457Caa8C47ED5B5DA410E40EFCbf3c;

    }

    function setDomainSeparator(string memory _domainName,
    uint256 _version,
    uint256 _chainId, 
    address _verifyingContract
    ) 
    external {
        DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes(_domainName)),
        keccak256(bytes(Strings.toString(_version))),
        _chainId,
        _verifyingContract
      )
    );
        domainName = _domainName;
        version = _version;
        chainId = _chainId;
        verifyingContract = _verifyingContract;

    }

    function setWhitelistSigner(address _whitelistSigner) external {
        whitelistSigner = _whitelistSigner;
    }

    function verifySignaturePresale(bytes calldata signature, 
        uint256 approvedLimit,
        address buyer) view external returns (bool){

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PRESALE_TYPEHASH, buyer, approvedLimit))
      )
    );

    address signer = digest.recover(signature);
    if(signer == address(0) || signer != whitelistSigner)
        return false;    
    
    return true;

    }

    function verifySignaturePresaleFree(bytes calldata signature, 
        uint256 approvedLimit,
        address buyer) view external returns (bool){

        bytes32 digest = keccak256(
        abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(FREEMINT_TYPEHASH, buyer, approvedLimit))
        )
        );

        address signer = digest.recover(signature);

        if(signer == address(0) || signer != whitelistSigner)
            return false;

        return true;
    }

}