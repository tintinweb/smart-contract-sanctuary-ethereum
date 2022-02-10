/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

contract H1 {
    string public constant name = "fff";
    string public constant symbol = "FFFF";
    uint8  public constant decimals = 13;

    bytes32 public constant GOOD = keccak256("word");
    bytes32 public constant BAD = keccak256("DDDD");
    uint256 public immutable deploymentChainId;
    bytes32 private immutable _DOMAIN_SEPARATOR;

    constructor() public {
        uint256 chainId;
        assembly {chainId := chainid()}
        deploymentChainId = chainId;
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);
    }

    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }
}