/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

pragma solidity 0.6.7;

abstract contract Setter {
    function transferERC20(address, address, uint256) external virtual;
    function deployDistributor(bytes32, uint256) external virtual;
    function sendTokensToDistributor(uint256) external virtual;
    function nonce() external virtual view returns (uint256);
    function balanceOf(address) external virtual view returns (uint256);
    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external virtual;
}

contract Proposal17 {
    Setter public constant GEB_DAO_TREASURY = Setter(0x7a97E2a5639f172b543d86164BDBC61B25F8c353);
    Setter public constant GEB_PROT = Setter(0x6243d8CEA23066d098a15582d81a598b4e8391F4);
    Setter public constant MERKLE_DISTRIBUTOR_FACTORY = Setter(0xb5Ed650eF207e051453B68A2138D7cb67CC85E41);
    Setter public constant GEB_DAO_STREAM_VAULT = Setter(0x0FA9c7Ad448e1a135228cA98672A0250A2636a47); // r
    Setter public constant GEB_DAO_STREAM_VAULT_2 = Setter(0x2df62660E30b8C5Bb211cA11e6525c6DD5D43200); // k

    function execute() public {
        // payroll
        address[8] memory receivers = [
            address(0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E),
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            0xCAFd432b7EcAfff352D92fcB81c60380d437E99D,
            0x7d35123708064B7f51ef481481cdF90cf30125C3,
            0x49C604E07338ce062efE23570e9732727Dc55F6f,
            0xBeAe83D58B6e26Ac6b906c4129e0D96722f5dEAa,
            0x297BF847Dcb01f3e870515628b36EAbad491e5E8,
            0x4A87a2A017Be7feA0F37f03F3379d43665486Ff8
        ];

        uint[8] memory amounts = [
            uint(852 ether),
            426 ether,
            314 ether,
            596 ether,
            128 ether,
            17 ether,
            426 ether,
            170 ether
        ];


        for (uint i; i < receivers.length; ++i)
            GEB_DAO_TREASURY.transferERC20(address(GEB_PROT), receivers[i], amounts[i]);

        // monthly distro
        MERKLE_DISTRIBUTOR_FACTORY.deployDistributor(0x47776b1e037cf5439f1d3ccfc4b11ddf34b1ba3578342e5224aae1d32f57f5c0, 4941311111103000000000);
        MERKLE_DISTRIBUTOR_FACTORY.sendTokensToDistributor(MERKLE_DISTRIBUTOR_FACTORY.nonce());

        // stream 1
        uint duration = 3 * 52 weeks;
        GEB_DAO_TREASURY.transferERC20(
            address(GEB_PROT),
            address(GEB_DAO_STREAM_VAULT),
            6000 ether - GEB_PROT.balanceOf(address(GEB_DAO_STREAM_VAULT))
        );
        GEB_DAO_STREAM_VAULT.createStream(
            0x0a453F46f8AE9a99b2B901A26b53e92BE6c3c43E,
            6000 ether - (6000 ether % duration),
            address(GEB_PROT),
            now,
            now + duration
        );

        // stream 2
        Setter(GEB_DAO_TREASURY).transferERC20(
            address(GEB_PROT),
            address(GEB_DAO_STREAM_VAULT_2),
            3000 ether
        );
        Setter(GEB_DAO_STREAM_VAULT_2).createStream(
            0x9640F1cB81B370186d1fcD3B9CBFA2854e49555e,
            3000 ether - (3000 ether % duration),
            address(GEB_PROT),
            now,
            now + duration
        );
    }
}