// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Referals {

    struct Data{
        uint256 count;
        address owner;
        address[] signers;
    }

    mapping ( uint256 => bool ) public referalIsUsed;
    mapping ( address => uint256 ) public referalCode;
    mapping ( uint256 => Data ) public signings;

    event ReferalCode(address indexed _to, uint _code);
    event Signed(address indexed _by, uint _code);

    bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant REFERAL_TYPEHASH = keccak256("Referal(uint256 code, string tokenId, uint256 price)"); 

    function getReferalCode() external {
        uint256 h = 5;
        uint8 i = 1;
        do {
            h = _hash(i++);
        } while ( referalIsUsed[ h ] );
        referalIsUsed[ h ] = true;
        referalCode[ msg.sender ] = h;
        Data storage d = signings[ h ];
        d.owner = msg.sender;
        
        emit ReferalCode(msg.sender, h );
    }

    function getKeyHash(uint256 code, string memory tokenId, uint256 price,
                        uint8 v, bytes32 r, bytes32 s) external view returns(address) {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("Referals")),
                keccak256(bytes("1")),
                5,
                address(this)
            )
        );

        bytes32 referalsHash = keccak256(
            abi.encode(
                REFERAL_TYPEHASH,
                code,
                keccak256(bytes(tokenId)),
                price
            )
        );

        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01",
        eip712DomainHash,
        referalsHash
        ));

        address signer = ecrecover(hash, v, r, s);

        return signer;
    }

    function _hash( uint8 c ) internal view returns (uint256) {
        uint256 aHash = 0;
        uint256 tmp;
        for (uint8 i = 1; i < 4 ; i++) {
            tmp = uint256(
                    keccak256(
                        abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                ( c + i )
                            )
                        )
                    ) % 0xFF;
                aHash |= uint256((tmp << ( i * 8 ) ));
            }
            return aHash;
    }

    function submitReferal(
        uint256 code,
        string memory tokenId,
        uint256 price,
        uint8 v,
        bytes32 r,
        bytes32 s ) external {
    
        // require( referalIsUsed[ code ] , "referal code doesn't exist" );
        Data storage d = signings[ code ];


        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("Referals")),
                keccak256(bytes("1")),
                5,
                address(this)
            )
        );

        bytes32 referalsHash = keccak256(
            abi.encode(
                REFERAL_TYPEHASH,
                code,
                keccak256(bytes(tokenId)),
                price
            )
        );

        bytes32 hash = keccak256(abi.encodePacked(
            "\x19\x01",
        eip712DomainHash,
        referalsHash
        ));

        address signer = ecrecover(hash, v, r, s);
        for ( uint i = 0; i < d.signers.length; i++ ) {
            if ( d.signers[i] == signer ) revert("Can't sign twice");
        }
        require(signings[code].owner != signer, "Can't sign own code");
    // require(block.timestamp < deadline, "deadline passed");
    // require(signer == msg.sender, "invalid signature");
        require(signer != address(0), "invalid signature");
        
        d.signers.push(signer);
        d.count += 1;

        emit Signed(msg.sender, code );
    }

}