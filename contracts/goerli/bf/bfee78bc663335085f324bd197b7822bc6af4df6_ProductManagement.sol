/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

pragma solidity >=0.4.21 <0.6.0;

contract ProductManagement {
    struct Part{
        address manufacturer;
        string serial_number;
        string part_type;
        string creation_date;
    }

    struct Product{
        address manufacturer;
        string serial_number;
        string product_type;
        string creation_date;
        bytes32[6] parts;
    }

    mapping(bytes32 => Part) public parts;
    mapping(bytes32 => Product) public products;

    constructor() public {
    }

    function concatenateInfoAndHash(address a1, string memory s1, string memory s2, string memory s3) private returns (bytes32){
        //First, get all values as bytes
        bytes20 b_a1 = bytes20(a1);
        bytes memory b_s1 = bytes(s1);
        bytes memory b_s2 = bytes(s2);
        bytes memory b_s3 = bytes(s3);

        //Then calculate and reserve a space for the full string
        string memory s_full = new string(b_a1.length + b_s1.length + b_s2.length + b_s3.length);
        bytes memory b_full = bytes(s_full);
        uint j = 0;
        uint i;
        for(i = 0; i < b_a1.length; i++){
            b_full[j++] = b_a1[i];
        }
        for(i = 0; i < b_s1.length; i++){
            b_full[j++] = b_s1[i];
        }
        for(i = 0; i < b_s2.length; i++){
            b_full[j++] = b_s2[i];
        }
        for(i = 0; i < b_s3.length; i++){
            b_full[j++] = b_s3[i];
        }

        //Hash the result and return
        return keccak256(b_full);
    }

    function buildPart(string memory serial_number, string memory part_type, string memory creation_date) public returns (bytes32){
        //Create hash for data and check if it exists. If it doesn't, create the part and return the ID to the user
        bytes32 part_hash = concatenateInfoAndHash(msg.sender, serial_number, part_type, creation_date);
        
        require(parts[part_hash].manufacturer == address(0), "Part ID already used");

        Part memory new_part = Part(msg.sender, serial_number, part_type, creation_date);
        parts[part_hash] = new_part;
        return part_hash;
    }

    function buildProduct(string memory serial_number, string memory product_type, string memory creation_date, bytes32[6] memory part_array) public returns (bytes32){
        //Check if all the parts exist, hash values and add to product mapping.
        uint i;
        for(i = 0;i < part_array.length; i++){
            require(parts[part_array[i]].manufacturer != address(0), "Inexistent part used on product");
        }

        //Create hash for data and check if exists. If it doesn't, create the part and return the ID to the user
        bytes32 product_hash = concatenateInfoAndHash(msg.sender, serial_number, product_type, creation_date);
        
        require(products[product_hash].manufacturer == address(0), "Product ID already used");

        Product memory new_product = Product(msg.sender, serial_number, product_type, creation_date, part_array);
        products[product_hash] = new_product;
        return product_hash;
    }

    function getParts(bytes32 product_hash) public returns (bytes32[6] memory){
        //The automatic getter does not return arrays, so lets create a function for that
        require(products[product_hash].manufacturer != address(0), "Product inexistent");
        return products[product_hash].parts;
    }
}