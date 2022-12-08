/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

pragma solidity 0.8.1;

interface IENSRegistry {

  function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);

}

interface IENSResolver { 

	function setContenthash(bytes32 node, bytes memory hash) external;

	function contenthash(bytes32 node) external returns (bytes memory);

}

contract Proposal {

  function executeProposal() external {
    bytes32 CLASSIC_ENS_SUBNODE = 0xe6ae31d630cc7a8279c0f1c7cbe6e7064814c47d1785fa2703d9ae511ee2be0c;
    bytes32 NOVA_ENS_SUBNODE = 0xc3964c598b56aeaee4c253283fb1ebb12510b95db00960589cdc62807a2537a0;
    bytes32 NOVA_ENS_LABEL = 0xc90e7e9184dce6e0d7fff2e19e72ffa35430aca54bd634ada091bef2d2bb0635;

    bytes memory CLASSIC_IPFS_HASH = hex"e30101701220d422ef6e800db34f50101daa4ea6b04365ab44b49bf58c00b54c1067befb7370";
    bytes memory NOVA_IPFS_HASH = hex"e30101701220a9d830d73355e8a37e8af1c48c234ea1b0089a0af77c0027137937f120501d93";

    address resolverAddress = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
    address registryAddress = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address governanceAddress = 0x5efda50f22d34F262c29268506C5Fa42cB56A1Ce;

    IENSRegistry(registryAddress).setSubnodeOwner(CLASSIC_ENS_SUBNODE, NOVA_ENS_LABEL, governanceAddress);

    IENSResolver(resolverAddress).setContenthash(CLASSIC_ENS_SUBNODE, CLASSIC_IPFS_HASH);
    IENSResolver(resolverAddress).setContenthash(NOVA_ENS_SUBNODE, NOVA_IPFS_HASH);
  }

}