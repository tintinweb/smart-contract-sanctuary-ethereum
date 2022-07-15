//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

// ÷import "hardhat/console.sol";

contract Database {

    type TableKey is uint32;
    type FieldKey is uint16;
    type ObjectPrimaryKey is uint128;

    // This value must be equal to the type size in bytes
    // of ObjectPrimaryKey. PRIMARY_KEY_SIZE_IN_BYTES = ObjectPrimaryKey.length
    uint256 public constant PRIMARY_KEY_SIZE_IN_BYTES = 16;
    uint256 public constant MAX_FIELDS_PER_OBJECT = 2**16 - 2;
    uint256 public constant MAX_FIELD_VALUE_IN_BYTES = 2**16;
    uint32 public constant MAX_QUERY_RESPONSE_BUFFER_SIZE = 100 * (1024 * 1024); // 100MB

    enum QueryType {
        FetchObject,
        FetchObjectList
    }

    enum FieldType {
        Value,

        // Resolves by using the main table and the referer object's primary key as the object key
        OwnedReference, 

        // Resolves by using the main table and the value stored in the field as the object key
        Reference,

        // Resolves by using the index table and the referer object's primary key as the index key
        // Then another lookup is necessary to fetch the object via the table referenced in the 
        // index and the reference primary key obtained by accessing the index
        IndexedReference,

        // Resolves by using the owned list table and the referer object's primary key to fetch
        // a list of objects from the owned list table.
        OwnedList,

        // Resolves by using the reference list table and the referer object's primary key to 
        // fetch a list of object's primary key. The for each object's primary key another
        // lookup is necessary to create a list of objects.
        ReferenceList
    }

    enum TableType {
        Object,
        OwnedList,
        ReferenceList,
        Index
    }

    struct Object {
        bool isValid;
        mapping(FieldKey => bytes) fields;
    }

    struct ObjectField {
        FieldKey key;
        bytes value;
    }

    struct ReferenceListTable {
        TableKey referencedTableKey;
        mapping(ObjectPrimaryKey => ObjectPrimaryKey[]) references;
    }

    struct IndexTable {
        TableKey referencedTableKey;
        mapping(ObjectPrimaryKey => ObjectPrimaryKey) references;
    }

    struct Selection {
        FieldKey fieldKey;
        FieldType fieldType;
        bool knownSize;
    }

    struct Query {
        QueryType queryType;
        ObjectPrimaryKey objectPrimaryKey;
        SelectionSet selectionSet;
        uint32 bufferSize;
    }

    struct FieldSelection {
        FieldKey fieldKey;
        FieldType fieldType;
        bool isSizeKnown;
    }

    struct SelectionSetResolutionData {
        TableKey tableKey;
        uint8 fieldsCount;
    }

    struct SelectionSet {
        uint8 depth; // MUST be >= 1
        FieldSelection[] fields;
        SelectionSetResolutionData[] resolutionTable;
    }

    struct FetchObjectQuery {
        TableKey tableKey;
        ObjectPrimaryKey objectKey;
        SelectionSet selectionSet;
    }

    struct InsertObjectOperation {
        TableKey tableKey;
        ObjectPrimaryKey objectKey;
        ObjectField[] fields;
    }

    struct InsertOperation {
        TableType tableType;
        TableKey tableKey;
        ObjectPrimaryKey primaryKey;
        // If 'tableType' is 'Object' then:
        //      - The main tables mapping is used as storage
        //      - 'fieldsOrReferenceKey' must contain an array of 'ObjectField's representing the fields of the one object to be inserted
        // If 'tableType' is 'OwnedList' then:
        //      - The owned list tables mapping is used as storage
        //      - fieldsOrReferenceKey' must contain an array of 'ObjectField's representing the fields of the one object to be inserted
        // If 'tableType' is 'ReferenceList' then:
        //      - The list reference tables mapping is used as storage
        //      - 'fieldsOrReferenceKey' must contain only 1 element with the reference that need to be inserted under the 'primaryKey'
        //      - Because 'fieldsOrReferenceKey' is reused to avoid having to add another field, then the only 'ObjectField' in this array
        //      must have its 'value' attribute set to the serialized referenced object's primary key and its 'key' attribute zeroed.
        ObjectField[] fieldsOrReferenceKey;
    }

    // An Object is a mapping(uint16 => bytes) where each object field is composed of a field key (uint16) and
    // a field value (bytes). Clients are responsible for translating human redable field name into binary 
    // field keys. By using uint16 to represent fields, the maximun amount of fields an object can have is
    // 2^16 - 2 = 65,535. Field key 0x0000 is reserved as the 'null' field key. As an example imagine we
    // have the following GraphQL type:
    //
    //      type User {
    //          firstName: String!
    //          lastName: String!
    //          age: Int!
    //      }
    //
    // then field keys would be:
    //
    //      * firstName => 0000000000000001 binary => 0x1 hexadecimal
    //      * lastName  => 0000000000000010 binary => 0x2 hexadecimal
    //      * age       => 0000000000000011 binary => 0x3 hexadecimal
    //
    // All field values should be serialized to bytes representation by the clients. Clients may choose
    // to encrypt values.
    //
    // A Table is a mapping(uint128 => Object) or mapping(uint256 => mapping(uint16 => bytes)) where
    // each object can be accessed by it's primary key which must be encoded into a uint128 value.
    //
    // Therefore tables is mapping(uint32 => Table) where each table is identified by it's table
    // key represented as uint32. Therefore the maximun amount of table is 2^32 - 2 = 4,294,967,294.
    // The table key 0x0 is reserved as the 'null' table key
    mapping (TableKey => mapping(ObjectPrimaryKey => Object)) private _tables;

    mapping (TableKey => mapping(ObjectPrimaryKey => Object[])) private _ownedListTables;

    mapping (TableKey => ReferenceListTable) private _referenceListTables;

    mapping (TableKey => IndexTable) private _indexTables;

    function resolve(Query calldata query) external view returns (bytes memory) {
        require(query.bufferSize <= MAX_QUERY_RESPONSE_BUFFER_SIZE, "Buffer size too big");
        require(query.queryType == QueryType.FetchObject, "Unsupported query type");

        if (query.queryType == QueryType.FetchObject) {
            bytes memory buffer = new bytes(query.bufferSize);
            uint32 bufferWrittenBytes = _fetchObject(query.objectPrimaryKey, query.selectionSet, buffer, 4);
            _copyUint32AsBytes(bufferWrittenBytes, buffer, 0);
            return buffer;
        } else {
            revert("Unsupported query type");
        }
    }

    function createReferenceListTable(TableKey tableKey, TableKey referenceTableKey) external { 
        _createReferenceListTable(tableKey, referenceTableKey);
    }

    function createIndexTable(TableKey indexTableKey, TableKey referencedTableKey) external {
        _createIndexTable(indexTableKey, referencedTableKey);
    }

    function insertObject(TableKey tableKey, ObjectPrimaryKey objectKey, ObjectField[] calldata fieldsList) external {
        _insertObject(tableKey, objectKey, fieldsList);
    }

    function insertObjectInOwnedList(TableKey tableKey, ObjectPrimaryKey primaryKey, ObjectField[] calldata fieldsList) external returns (uint256) {
        return _insertObjectInOwnedList(tableKey, primaryKey, fieldsList);
    }

    function insertReferenceInList(TableKey tableKey, ObjectPrimaryKey primaryKey, ObjectPrimaryKey referenceKey) external returns (uint256) {
        return _insertReferenceInList(tableKey, primaryKey, referenceKey);
    }

    function batchInsert(InsertOperation[] calldata inserts) external {
        for (uint i = 0; i < inserts.length; ++i) {
            InsertOperation calldata insert = inserts[i];
            if (insert.tableType == TableType.Object) {
                _insertObject(insert.tableKey, insert.primaryKey, insert.fieldsOrReferenceKey);
            } else if (insert.tableType == TableType.OwnedList) {
                _insertObjectInOwnedList(insert.tableKey, insert.primaryKey, insert.fieldsOrReferenceKey);
            } else if (insert.tableType == TableType.ReferenceList) {
                require(insert.fieldsOrReferenceKey.length == 1, "fieldsOrReferenceKey must contain only 1 object's fields");
                require(FieldKey.unwrap(insert.fieldsOrReferenceKey[0].key) == uint16(0), "ObjectField.key must be zero");
                require(insert.fieldsOrReferenceKey[0].value.length == PRIMARY_KEY_SIZE_IN_BYTES, "Reference value invalid size");
                ObjectPrimaryKey referencePrimaryKey = ObjectPrimaryKey.wrap(uint128(bytes16(insert.fieldsOrReferenceKey[0].value)));
                _insertReferenceInList(insert.tableKey, insert.primaryKey, referencePrimaryKey);
            } else if (insert.tableType == TableType.Index) {
                require(insert.fieldsOrReferenceKey.length == 1, "fieldsOrReferenceKey must contain only 1 object's fields");
                require(FieldKey.unwrap(insert.fieldsOrReferenceKey[0].key) == uint16(0), "ObjectField.key must be zero");
                require(insert.fieldsOrReferenceKey[0].value.length == PRIMARY_KEY_SIZE_IN_BYTES, "Reference value invalid size");
                ObjectPrimaryKey referencePrimaryKey = ObjectPrimaryKey.wrap(uint128(bytes16(insert.fieldsOrReferenceKey[0].value)));
                _indexObject(insert.tableKey, insert.primaryKey, referencePrimaryKey);
            } else {
                revert("Unsupported table type");
            }
        }
    }

    function indexObject(TableKey indexTableKey, ObjectPrimaryKey indexPrimaryKey, ObjectPrimaryKey referenceKey) external {
        _indexObject(indexTableKey, indexPrimaryKey, referenceKey);
    }

    function _insertObject(TableKey tableKey, ObjectPrimaryKey objectKey, ObjectField[] calldata fieldsList) private {
        require(TableKey.unwrap(tableKey) != uint32(0), "Cannot insert into the zero table key");
        require(ObjectPrimaryKey.unwrap(objectKey) != uint128(0), "Cannot insert into the zero primary key");
        require(!_tables[tableKey][objectKey].isValid, "Object already exists");
        require(fieldsList.length <= MAX_FIELDS_PER_OBJECT, "Too many fields");
        
        Object storage object = _tables[tableKey][objectKey];
        for (uint64 i = 0; i < fieldsList.length; ++i) {
            require(FieldKey.unwrap(fieldsList[i].key) != uint16(0), "Cannot insert into the zero field key");
            require(fieldsList[i].value.length <= MAX_FIELD_VALUE_IN_BYTES, "Field too big");
            object.fields[fieldsList[i].key] = fieldsList[i].value;
        }
        object.isValid = true;
    }

    function _insertObjectInOwnedList(TableKey tableKey, ObjectPrimaryKey primaryKey, ObjectField[] calldata fieldsList) private returns (uint256) {
        require(TableKey.unwrap(tableKey) != uint32(0), "Cannot insert into the zero table key");
        require(ObjectPrimaryKey.unwrap(primaryKey) != uint128(0), "Cannot insert into the zero primary key");
        require(fieldsList.length > 0, "Must contain at least 1 field");
        require(fieldsList.length <= MAX_FIELDS_PER_OBJECT, "Too many fields");

        for (uint64 i = 0; i < fieldsList.length; ++i) {
            require(FieldKey.unwrap(fieldsList[i].key) != uint16(0), "Cannot insert into the zero field key");
            require(fieldsList[i].value.length <= MAX_FIELD_VALUE_IN_BYTES, "Field too big");
        }
 
        Object[] storage objects = _ownedListTables[tableKey][primaryKey];
        Object storage object = objects.push();
        for (uint64 i = 0; i < fieldsList.length; ++i) {
            object.fields[fieldsList[i].key] = fieldsList[i].value;
        }
        object.isValid = true;

        return objects.length;
    }

    function _insertReferenceInList(TableKey tableKey, ObjectPrimaryKey primaryKey, ObjectPrimaryKey referenceKey) private returns (uint256) {
        require(TableKey.unwrap(tableKey) != uint32(0), "Cannot insert into the zero table key");
        require(ObjectPrimaryKey.unwrap(primaryKey) != uint128(0), "Cannot insert into the zero primary key");
        require(ObjectPrimaryKey.unwrap(referenceKey) != uint128(0), "Cannot insert a reference into the zero key");

        ReferenceListTable storage table = _referenceListTables[tableKey];
        require(TableKey.unwrap(table.referencedTableKey) != uint32(0), "Cannot insert into a non-intialized referce list table");

        ObjectPrimaryKey[] storage references = table.references[primaryKey];
        references.push(referenceKey);

        return references.length;
    }

    function _indexObject(TableKey indexTableKey, ObjectPrimaryKey indexPrimaryKey, ObjectPrimaryKey referenceKey) private {
        require(TableKey.unwrap(indexTableKey) != uint32(0), "Cannot insert into the zero table key");
        require(ObjectPrimaryKey.unwrap(indexPrimaryKey) != uint128(0), "Cannot insert into the zero primary key");
        require(ObjectPrimaryKey.unwrap(referenceKey) != uint128(0), "Cannot insert a reference into the zero key");

        IndexTable storage index = _indexTables[indexTableKey];
        require(TableKey.unwrap(index.referencedTableKey) != uint32(0), "Cannot insert into a non-intialized index table");
        require(_tables[index.referencedTableKey][referenceKey].isValid, "Cannot index a non-existant object");

        index.references[indexPrimaryKey] = referenceKey;
    }

    function _createIndexTable(TableKey indexTableKey, TableKey referencedTableKey) private {
        require(TableKey.unwrap(indexTableKey) != uint32(0), "Cannot create table with zero key");
        require(TableKey.unwrap(referencedTableKey) != uint32(0), "Cannot create a reference to table key zero");

        IndexTable storage table = _indexTables[indexTableKey];
        require(TableKey.unwrap(table.referencedTableKey) == uint32(0), "Table already created");

        table.referencedTableKey = referencedTableKey;
    }

    function _createReferenceListTable(TableKey tableKey, TableKey referencedTableKey) private {
        require(TableKey.unwrap(tableKey) != uint32(0), "Cannot create table with zero key");
        require(TableKey.unwrap(referencedTableKey) != uint32(0), "Cannot create a reference to table key zero");

        ReferenceListTable storage table = _referenceListTables[tableKey];
        require(TableKey.unwrap(table.referencedTableKey) == uint32(0), "Table already created");

        table.referencedTableKey = referencedTableKey;
    }

    function _fetchObject(ObjectPrimaryKey  primaryKey, SelectionSet calldata selectionSet, bytes memory buffer, uint32 bufferOffset) private view returns (uint32) {
        require(ObjectPrimaryKey.unwrap(primaryKey) != uint128(0), "Cannot query over the zero primary key");
        require(selectionSet.depth >= 1, "Selection set depth must be at least 1");
        require(selectionSet.fields.length > 0, "Selection set fields cannot be empty");
        require(selectionSet.resolutionTable.length > 0, "Selection set resolution table cannot be empty");

        Object storage currentObjectCache = getRootObject(primaryKey, selectionSet);
        if (!currentObjectCache.isValid) {
            return 0;
        }

        ResolutionExecutionState memory state = newResolutionExecutionState(primaryKey, selectionSet);
        // TODO is uint64 OK?
        uint64 selectionSetFieldsIndex = 0;
        while (arePendingFieldsToResolve(state) || arePendingObjectsToResolve(state)) {
            assert(currentObjectCache.isValid);

            FieldSelection calldata selection = selectionSet.fields[selectionSetFieldsIndex];
            require(FieldKey.unwrap(selection.fieldKey) != uint16(0), "Cannot select the field key zero");
            if (selection.fieldType == FieldType.Value) {
                bytes storage fieldValue = currentObjectCache.fields[selection.fieldKey];
                if (!selection.isSizeKnown) {
                    state.bytesWritten += _copyUint24AsBytes(uint24(fieldValue.length), buffer, bufferOffset + state.bytesWritten);
                }
                state.bytesWritten += _copyFieldValueData(fieldValue, buffer, bufferOffset + state.bytesWritten);
                markFieldResolved(state);
            } else if (selection.fieldType == FieldType.Reference) {
                bytes storage fieldValue = currentObjectCache.fields[selection.fieldKey];
                // TODO What do we do if the reference is null? Meaning fieldValue is empty
                assert(fieldValue.length == PRIMARY_KEY_SIZE_IN_BYTES);
                ObjectPrimaryKey referencePrimaryKey = ObjectPrimaryKey.wrap(uint128(bytes16(fieldValue)));
                
                markFieldResolved(state);
                TableKey referenceTableKey = pushReferenceResolution(state, selectionSet, referencePrimaryKey);
                
                currentObjectCache = _tables[referenceTableKey][referencePrimaryKey];
            } else if (selection.fieldType == FieldType.OwnedReference) {
                // Owned references use the parent object (or the object that owns the reference) primary key
                // in the reference type's table. References that are owned don't have their own primary key
                ObjectPrimaryKey referencePrimaryKey = getCurrentObjectKey(state);

                markFieldResolved(state);
                TableKey referenceTableKey = pushReferenceResolution(state, selectionSet, referencePrimaryKey);
                
                currentObjectCache = _tables[referenceTableKey][referencePrimaryKey];
            } else if (selection.fieldType == FieldType.IndexedReference) {
                // Indexed references use the parent object (or the object that owns the reference) primary key
                // in the index table.
                ObjectPrimaryKey indexKey = getCurrentObjectKey(state);

                markFieldResolved(state);
                TableKey referenceTableKey = pushReferenceResolution(state, selectionSet, indexKey);
                
                IndexTable storage index = _indexTables[referenceTableKey];
                currentObjectCache = _tables[index.referencedTableKey][index.references[indexKey]];
            } else if (selection.fieldType == FieldType.OwnedList) {
                markFieldResolved(state);
                (uint128 objectsCount, TableKey listTableKey, ObjectPrimaryKey referencePrimaryKey) = 
                    pushReferenceListResolution(state, selectionSet, true, selectionSetFieldsIndex + 1);
                // TODO review is having 2^128 is too much, probably uint32 would be more than enough
                state.bytesWritten += _copyUint128AsBytes(objectsCount, buffer, bufferOffset + state.bytesWritten);

                if (objectsCount > 0) {
                    currentObjectCache =  _ownedListTables[listTableKey][referencePrimaryKey][0];
                }
            }  else if (selection.fieldType == FieldType.ReferenceList) {
                markFieldResolved(state);
                (uint128 objectsCount, TableKey listTableKey, ObjectPrimaryKey referencePrimaryKey) = 
                    pushReferenceListResolution(state, selectionSet, false, selectionSetFieldsIndex + 1);
                // TODO review is having 2^128 is too much, probably uint32 would be more than enough
                state.bytesWritten += _copyUint128AsBytes(objectsCount, buffer, bufferOffset + state.bytesWritten);

                ReferenceListTable storage referenceListTable = _referenceListTables[listTableKey];
                currentObjectCache =  _tables[referenceListTable.referencedTableKey][referenceListTable.references[referencePrimaryKey][0]];
            } else {
                revert("Unsupported field selection type");
            }

            selectionSetFieldsIndex += 1;

            // If there are no more fields to resolve we need to pop the resolution
            // stack and continue resolving pending fields from previous object unless
            // we are resolving a list reference, in which case, we first need to
            // check if there are pending objects to be resolved before poping
            // the stack
            if (!arePendingFieldsToResolve(state)) {
                markObjectResolved(state);
                if (arePendingObjectsToResolve(state)) {
                    SelectionSetResolutionData calldata resolutionData = getResolutionData(state, selectionSet);
                    ObjectPrimaryKey referencePrimaryKey = getCurrentObjectKey(state);
                    
                    // We reset the index to iterate over the selection set because the selection set is the 
                    // same but applied to the next object in the list.
                    selectionSetFieldsIndex = getCurrentListFirstFieldIndex(state);
                    setPendingFieldsToResolve(state, resolutionData.fieldsCount);

                    if (isCurrentResolutionAnOwnedList(state)) {
                        Object[] storage objects = _ownedListTables[resolutionData.tableKey][referencePrimaryKey];
                        uint128 currentObjectIndex = uint128(objects.length) - getPendingObjectsToResolve(state);
                        currentObjectCache = objects[currentObjectIndex];
                    } else {
                        ReferenceListTable storage referenceListTable = _referenceListTables[resolutionData.tableKey];
                        ObjectPrimaryKey[] storage objectKeys = referenceListTable.references[referencePrimaryKey];
                        uint128 currentObjectIndex = uint128(objectKeys.length) - getPendingObjectsToResolve(state);
                        currentObjectCache = _tables[referenceListTable.referencedTableKey][objectKeys[currentObjectIndex]];
                    }
                } else {
                    // This check is needed to avoid popping the last element of the stack (which represents the resolution)
                    // for the root object. 
                    if (!isResolvingRootObject(state)) {
                        popResolutionStack(state);
                    }
                    currentObjectCache = _tables[getReferenceParentTableKey(state, selectionSet)][getCurrentObjectKey(state)];
                }
            }

        }

        return state.bytesWritten;
    } 

    function _copyFieldValueData(bytes storage fieldValueData, bytes memory buffer, uint32 offset) private view returns (uint24) {
        assert(fieldValueData.length < MAX_FIELD_VALUE_IN_BYTES);
        require(offset + fieldValueData.length <= buffer.length, "Destination buffer is not big enough");
        // TODO is this the most efficient way of copying buffers?
        // TODO validate if restraining field value to a max of 16MB (uint24) is OK
        uint24 i = 0;
        for(; i < fieldValueData.length; ++i) { 
            buffer[offset] = fieldValueData[i];
            offset++;
        }
        return i;
    }

    // Copy a uint32 byte by byte big endian style to the given buffer
    function _copyUint24AsBytes(uint24 value, bytes memory buffer, uint32 offset) private pure returns (uint8) {
        require(offset + 3 <= buffer.length, "Destination buffer is not big enough");
        
        // TODO is this the most efficient way of encoding a type?
        // should we pack it?
        buffer[offset] = bytes1(uint8((value & 0xFF0000) >> 16));
        buffer[offset + 1] = bytes1(uint8((value & 0x00FF00) >> 8));
        buffer[offset + 2] = bytes1(uint8(value & 0x0000FF));

        return 3;
    }

    // Copy a uint32 byte by byte big endian style to the given buffer
    function _copyUint32AsBytes(uint32 value, bytes memory buffer, uint32 offset) private pure returns (uint8) {
        require(offset + 4 <= buffer.length, "Destination buffer is not big enough");
        
        // TODO is this the most efficient way of encoding a type?
        // should we pack it?
        buffer[offset] = bytes1(uint8((value & 0xFF000000) >> 24));
        buffer[offset + 1] = bytes1(uint8((value & 0x00FF0000) >> 16));
        buffer[offset + 2] = bytes1(uint8((value & 0x0000FF00) >> 8));
        buffer[offset + 3] = bytes1(uint8(value & 0x000000FF));

        return 4;
    }

    // Copy a uint128 byte by byte big endian style to the given buffer
    function _copyUint128AsBytes(uint128 value, bytes memory buffer, uint32 offset) private pure returns (uint8) {
        require(offset + 16 <= buffer.length, "Destination buffer is not big enough");

        uint128 mask = 0xFF000000000000000000000000000000;
        for (uint8 i; i < 16; ++i) {
            buffer[offset + i] = bytes1(uint8((value & mask) >> (120 - 8*i)));
            mask = mask >> 8;
        }
        return 16;
    }


    struct ResolutionFrame {
        ObjectPrimaryKey objectKey;
        uint8 pendingFieldsToResolve;
        
        // When resolving any reference (list or single) this is used
        // to save the reference parent object's resolution table index
        // in order to know which table does the parent object belongs
        // to when we resolve all the reference fields and we pop the
        // resolution stack. Knowing the table index allows to fetch
        // the parent object again, cache it, and keep on resolving
        // pending fields
        uint8 referenceParentResolutionTableIndex;
        
        // -------- This fields are only used for list reference fields --------
        uint128 pendingObjectsToResolve;
        uint64 currentListFirstFieldIndex;
        bool isOwnedList;
    }

    struct ResolutionExecutionState {
        uint32 bytesWritten;
        uint8 resolutionTableIndex;
        uint8 resolutionStackIndex;
        ResolutionFrame[] resolutionStack;
    }

    function getRootObject(ObjectPrimaryKey primaryKey, SelectionSet calldata selectionSet) internal view returns (Object storage) {
        SelectionSetResolutionData calldata rootResolutionData = selectionSet.resolutionTable[0];
        require(TableKey.unwrap(rootResolutionData.tableKey) != uint32(0), "Cannot fetch object from a table with key zero");
        mapping(ObjectPrimaryKey => Object) storage table = _tables[rootResolutionData.tableKey];
        return table[primaryKey];
    }

    function newResolutionExecutionState(ObjectPrimaryKey primaryKey, SelectionSet calldata selectionSet) internal pure returns (ResolutionExecutionState memory) {
        SelectionSetResolutionData calldata rootResolutionData = selectionSet.resolutionTable[0];
        ResolutionExecutionState memory state = ResolutionExecutionState({
            bytesWritten: 0,
            resolutionTableIndex: 0,
            resolutionStackIndex: 0,
            resolutionStack: new ResolutionFrame[](selectionSet.depth)
        });
        
        // Initializes resolution stack by pushing the root object's type and field selection
        // count to be resolved.
        state.resolutionStack[0].objectKey = primaryKey;
        state.resolutionStack[0].pendingFieldsToResolve = rootResolutionData.fieldsCount;

        return state;
    }

    function isResolvingRootObject(ResolutionExecutionState memory state) internal pure returns (bool) {
        return state.resolutionStackIndex == 0;
    }

    function arePendingFieldsToResolve(ResolutionExecutionState memory state) internal pure returns (bool) {
        return state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve > 0;
    }

    function arePendingObjectsToResolve(ResolutionExecutionState memory state) internal pure returns (bool) {
        return state.resolutionStack[state.resolutionStackIndex].pendingObjectsToResolve > 0;
    }

    function getPendingObjectsToResolve(ResolutionExecutionState memory state) internal pure returns (uint128) {
        return state.resolutionStack[state.resolutionStackIndex].pendingObjectsToResolve;
    }

    function markObjectResolved(ResolutionExecutionState memory state) internal pure {
        ResolutionFrame memory resolutionFrame = state.resolutionStack[state.resolutionStackIndex];
        if (resolutionFrame.pendingObjectsToResolve > 0) {
            resolutionFrame.pendingObjectsToResolve--;
        }
    }

    function markFieldResolved(ResolutionExecutionState memory state) internal pure {
        state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve--;
    }

    function getResolutionData(ResolutionExecutionState memory state, SelectionSet calldata selectionSet) internal pure returns (SelectionSetResolutionData calldata) {
        return selectionSet.resolutionTable[state.resolutionTableIndex];
    }

    function getCurrentObjectKey(ResolutionExecutionState memory state) internal pure returns (ObjectPrimaryKey) {
        return state.resolutionStack[state.resolutionStackIndex].objectKey;
    }

    function getCurrentListFirstFieldIndex(ResolutionExecutionState memory state) internal pure returns (uint64) {
        return state.resolutionStack[state.resolutionStackIndex].currentListFirstFieldIndex;
    }

    function setPendingFieldsToResolve(ResolutionExecutionState memory state, uint8 value) internal pure {
        state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve = value;
    }

    function isCurrentResolutionAnOwnedList(ResolutionExecutionState memory state) internal pure returns (bool) {
        return state.resolutionStack[state.resolutionStackIndex].isOwnedList;
    }

    function popResolutionStack(ResolutionExecutionState memory state) internal pure {
        assert(state.resolutionStackIndex > 0);

        state.resolutionStack[state.resolutionStackIndex].objectKey = ObjectPrimaryKey.wrap(0);
        state.resolutionStack[state.resolutionStackIndex].currentListFirstFieldIndex = 0;
        state.resolutionStack[state.resolutionStackIndex].pendingObjectsToResolve = 0;
        state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve = 0;
        state.resolutionStack[state.resolutionStackIndex].isOwnedList = false;

        state.resolutionStackIndex--;        
    }

    function getReferenceParentTableKey(ResolutionExecutionState memory state, SelectionSet calldata selectionSet) internal pure returns (TableKey) {
        uint8 tableIndex = state.resolutionStack[state.resolutionStackIndex].referenceParentResolutionTableIndex;
        return selectionSet.resolutionTable[tableIndex].tableKey;
    }

    function pushResolutionStack(ResolutionExecutionState memory state, SelectionSet calldata selectionSet) internal pure {
        // We cache the reference parent object's resolution table index in the current stack
        // in order to be able to fetch the parent object again after all fields reference are
        // resolved
        state.resolutionStack[state.resolutionStackIndex].referenceParentResolutionTableIndex = state.resolutionTableIndex;
        
        state.resolutionStackIndex++;
        state.resolutionTableIndex++;

        // This should not happen unless the client constructed an invalid query
        assert(
            state.resolutionTableIndex < selectionSet.resolutionTable.length && 
            state.resolutionStackIndex < selectionSet.depth
        );
    }

    function pushReferenceResolution(ResolutionExecutionState memory state, SelectionSet calldata selectionSet, ObjectPrimaryKey referencePrimaryKey) internal pure returns (TableKey) {
        pushResolutionStack(state, selectionSet);

        SelectionSetResolutionData calldata resolutionData = selectionSet.resolutionTable[state.resolutionTableIndex];
        state.resolutionStack[state.resolutionStackIndex].objectKey = referencePrimaryKey;
        state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve = resolutionData.fieldsCount;
        // This must be all zero. They are only used for list references
        state.resolutionStack[state.resolutionStackIndex].pendingObjectsToResolve = 0;
        state.resolutionStack[state.resolutionStackIndex].currentListFirstFieldIndex = 0;

        return resolutionData.tableKey;
    }

    function pushReferenceListResolution(
        ResolutionExecutionState memory state, 
        SelectionSet calldata selectionSet, 
        bool isOwned,
        uint64 firstFieldIndex) internal view returns (uint128, TableKey, ObjectPrimaryKey) {
        ObjectPrimaryKey referencePrimaryKey = getCurrentObjectKey(state);

        pushResolutionStack(state, selectionSet);

        SelectionSetResolutionData calldata resolutionData = selectionSet.resolutionTable[state.resolutionTableIndex];
        uint128 objectsCount;
        if (isOwned) {
            objectsCount =  uint128(_ownedListTables[resolutionData.tableKey][referencePrimaryKey].length);
        } else {
            objectsCount = uint128(_referenceListTables[resolutionData.tableKey].references[referencePrimaryKey].length);
        }
        if (objectsCount == 0) {
            state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve = 0;
            state.resolutionStack[state.resolutionStackIndex].pendingObjectsToResolve = 0;
            state.resolutionStack[state.resolutionStackIndex].currentListFirstFieldIndex = 0;
        } else {
            state.resolutionStack[state.resolutionStackIndex].objectKey = referencePrimaryKey;
            state.resolutionStack[state.resolutionStackIndex].currentListFirstFieldIndex = firstFieldIndex;
            state.resolutionStack[state.resolutionStackIndex].pendingObjectsToResolve = objectsCount;
            state.resolutionStack[state.resolutionStackIndex].pendingFieldsToResolve = resolutionData.fieldsCount;
            state.resolutionStack[state.resolutionStackIndex].isOwnedList = isOwned;
        }

        return (objectsCount, resolutionData.tableKey, referencePrimaryKey);
    }
}