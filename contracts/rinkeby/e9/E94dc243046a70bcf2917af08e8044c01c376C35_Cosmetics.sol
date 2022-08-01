/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Cosmetics{
    address private manager;

    constructor(){
        manager = msg.sender;
    }

    enum ORDER_STATUS{
        CREATED,
        ORDERING,
        ACCEPTED,
        DENIED,
        DELIVERING,
        RECEIVED,
        CANCEL
    }

    enum BATCH_STATUS{
        CREATED,
        PREPARE_MAT,
        PRODUCE,
        CHECK_QUAL,
        PACKING,
        CONFIRM,
        DONE,
        CANCEL
    }

    struct ProductInfo{
        string name;
        uint quantity;
        string unit;
    }

    struct ProductOrderInfo{
        uint batch_id;
        uint quantity;
    }

    struct Contact{
        string name;
        address account;
    }

    struct OrderEvent{
        ORDER_STATUS status;
        uint timestamp;
    }

    struct Order{
        uint id;
        Contact supplier;
        Contact customer;
        uint order_date;
        uint received_date;
        ProductInfo[] order_list;
        OrderEvent[] timeline;
        ProductOrderInfo[] product_order_list;
    }

    struct Material{
        uint id;
        uint order_id;
        ProductInfo mat_info;
    }

    struct ProductMaterial{
        uint mat_id;
        uint quantity;
        string check_result;
        uint check_timestamp;
    }

    struct ProduceInfo{
        string name;
        uint started_at;
        uint finished_at;
    }

    struct ProductCheck{
        string name;
        string result;
        uint timestamp;
    }
    
    struct BatchEvent{
        BATCH_STATUS status;
        uint timestamp;
    }

    struct ProductBatch{
        uint id;
        ProductInfo product_info;
        uint create_at;
        uint finished_at;
        ProductMaterial[] mat_list;
        ProduceInfo[] produce_list;
        ProductCheck[] check_list;
        BatchEvent[] timeline;
    }

    event reload();

    uint public order_count = 0;
    mapping(uint => Order) public orders;

    uint public material_count = 0;
    mapping(uint => Material) public materials;

    uint public batch_count = 0;
    mapping(uint => ProductBatch) public batchs;

    function createOrder(Contact memory supplier, Contact memory customer, ProductInfo[] memory order_list, uint rd) external{
        Order storage order = orders[++order_count];
        order.id = order_count;
        order.supplier = supplier;
        order.customer = customer;
        order.order_date = block.timestamp;
        order.received_date = rd;
        order.timeline.push(OrderEvent(ORDER_STATUS.CREATED, block.timestamp));

        uint len = order_list.length;
        for(uint i=0; i<len; i++){
            order.order_list.push(order_list[i]);
        }
    }

    function createPurchaseProductOrder(Contact memory supplier, Contact memory customer, ProductOrderInfo[] memory order_list, uint rd) external{
        Order storage order = orders[++order_count];
        order.id = order_count;
        order.supplier = supplier;
        order.customer = customer;
        order.order_date = block.timestamp;
        order.received_date = rd;
        order.timeline.push(OrderEvent(ORDER_STATUS.CREATED, block.timestamp));
        
        uint len = order_list.length;
        for(uint i=0; i<len; i++){
            batchs[order_list[i].batch_id].product_info.quantity -= order_list[i].quantity;
            order.product_order_list.push(order_list[i]);
        }
    }

    function changeOrderStatus(uint order_id, ORDER_STATUS new_status) external{
        uint timeline_count = orders[order_id].timeline.length;
        ORDER_STATUS current_status = orders[order_id].timeline[timeline_count - 1].status;

        require(current_status != ORDER_STATUS.RECEIVED && current_status != ORDER_STATUS.DENIED && current_status != ORDER_STATUS.CANCEL && new_status > current_status);

        if(new_status == ORDER_STATUS.ACCEPTED || new_status == ORDER_STATUS.DENIED || new_status == ORDER_STATUS.DELIVERING){
            require(orders[order_id].supplier.account == msg.sender);
            orders[order_id].timeline.push(OrderEvent(new_status, block.timestamp));
        }
        else if(new_status == ORDER_STATUS.ORDERING || new_status == ORDER_STATUS.CANCEL || new_status == ORDER_STATUS.RECEIVED){
            require(orders[order_id].customer.account == msg.sender);

            orders[order_id].timeline.push(OrderEvent(new_status, block.timestamp));
        }

        emit reload();
    }

    function receiveMaterialOrder(uint order_id) external {
        uint timeline_count = orders[order_id].timeline.length;
        ORDER_STATUS current_status = orders[order_id].timeline[timeline_count - 1].status;
        require(current_status == ORDER_STATUS.DELIVERING);
            
        require(orders[order_id].customer.account == msg.sender);

        uint order_product_count = orders[order_id].order_list.length;
        for(uint i=0; i<order_product_count; i++){
            Material storage material = materials[++material_count];
            material.id = material_count;
            material.order_id = order_id;
            material.mat_info = orders[order_id].order_list[i];
        }

        orders[order_id].timeline.push(OrderEvent(ORDER_STATUS.RECEIVED, block.timestamp));

        emit reload();
    }

    function getOrderList(address account, bool isBySupplier) external view returns(Order[] memory){
        Order[] memory list = new Order[](order_count);

        uint count = 0;
        for(uint i=1; i <= order_count; i++){
            if(isBySupplier == true){
                if(orders[i].supplier.account == account){
                    list[count++] = orders[i];
                }
            }
            else{
                if(orders[i].customer.account == account){
                    list[count++] = orders[i];
                }
            }
        }

        return list;
    }

    function getOrderById(uint id) external view returns(Order memory){
        return orders[id];
    }

    function getPurchaseOrderName(uint id) external view returns(string[] memory){
        uint len = orders[id].product_order_list.length;
        string[] memory product_name_list = new string[](len);

        for(uint i=0; i<len; i++){
            product_name_list[i] = batchs[orders[id].product_order_list[i].batch_id].product_info.name;
        }

        return product_name_list;
    }

    function getMaterialList() external view returns(Material[] memory, Order[] memory){
        Material[] memory mat_list = new Material[](material_count);
        Order[] memory mat_order_list = new Order[](material_count);

        for(uint i=1; i<=material_count; i++){
            mat_list[i-1] = materials[i];
            mat_order_list[i-1] = orders[materials[i].order_id];
        }

        return (mat_list, mat_order_list);
    }

    function createProductBatch(ProductInfo memory product_info, ProductMaterial[] memory mat_list, uint sd, uint ed) external {
        ProductBatch storage batch = batchs[++batch_count];
        batch.id = batch_count;
        batch.product_info = product_info;
        batch.create_at = sd;
        batch.finished_at = ed;
        batch.timeline.push(BatchEvent(BATCH_STATUS.CREATED, block.timestamp));

        uint len = mat_list.length;
        for(uint i=0; i<len; i++){
            materials[mat_list[i].mat_id].mat_info.quantity -= mat_list[i].quantity;
            batch.mat_list.push(mat_list[i]);
        }
    }

    function changeProductBatchStatus(uint batch_id, BATCH_STATUS new_status) external{
        uint timeline_count = batchs[batch_id].timeline.length;
        BATCH_STATUS current_status = batchs[batch_id].timeline[timeline_count - 1].status;

        require(current_status != BATCH_STATUS.DONE && current_status != BATCH_STATUS.CANCEL && new_status > current_status);
        batchs[batch_id].timeline.push(BatchEvent(new_status, block.timestamp));

        emit reload();
    } 

    function addProductMaterialCheck(uint batch_id, uint index, string memory check_result) external {
        uint timeline_count = batchs[batch_id].timeline.length;
        BATCH_STATUS current_status = batchs[batch_id].timeline[timeline_count - 1].status;
        require(current_status == BATCH_STATUS.PREPARE_MAT);

        batchs[batch_id].mat_list[index].check_result = check_result;
        batchs[batch_id].mat_list[index].check_timestamp = block.timestamp;

        emit reload();
    }

    function addProduceInfo(uint batch_id, string memory name) external{
        uint timeline_count = batchs[batch_id].timeline.length;
        BATCH_STATUS current_status = batchs[batch_id].timeline[timeline_count - 1].status;
        require(current_status == BATCH_STATUS.PRODUCE);

        batchs[batch_id].produce_list.push(ProduceInfo(name, block.timestamp, 0));

        emit reload();
    }

    function finishProduce(uint batch_id, uint index) external {
        uint timeline_count = batchs[batch_id].timeline.length;
        BATCH_STATUS current_status = batchs[batch_id].timeline[timeline_count - 1].status;
        require(current_status == BATCH_STATUS.PRODUCE);

        batchs[batch_id].produce_list[index].finished_at = block.timestamp;

        emit reload();
    }

    function addProductCheck(uint batch_id, string memory name, string memory result) external {
        uint timeline_count = batchs[batch_id].timeline.length;
        BATCH_STATUS current_status = batchs[batch_id].timeline[timeline_count - 1].status;
        require(current_status == BATCH_STATUS.CHECK_QUAL);

        batchs[batch_id].check_list.push(ProductCheck(name, result, block.timestamp));
        
        emit reload();
    }
    
    function getProductBatchList(BATCH_STATUS status, bool isByStatus) external view returns(ProductBatch[] memory) {
        ProductBatch[] memory list = new ProductBatch[](batch_count);

        uint count = 0; 
        for(uint i=1; i<=batch_count; i++){
            if(isByStatus == true){
                uint timeline_count = batchs[i].timeline.length;
                BATCH_STATUS current_status = batchs[i].timeline[timeline_count - 1].status;
                if(current_status == status){
                    list[count++] = batchs[i];
                }
            }
            else{
                list[count++] = batchs[i];
            }
        }

        return list;
    }

    function getProductBatch(uint batch_id) external view returns(ProductBatch memory, Material[] memory, Order[] memory){
        uint len = batchs[batch_id].mat_list.length;

        Material[] memory mat_list = new Material[](len);
        Order[] memory mat_order_list = new Order[](len);
        
        for(uint i=0; i<len; i++){
            uint mat_id = batchs[batch_id].mat_list[i].mat_id;

            mat_list[i] = materials[mat_id];
            mat_order_list[i] = orders[materials[mat_id].order_id];
        }
        
        return (batchs[batch_id], mat_list, mat_order_list);
    }
}