pragma solidity =0.6.0;

contract Registration {
    

    address private owner;
    mapping(address=>bool) public retailers;
    mapping(address=>bool) public suppliers;

    event RetailerRegistered(address retailer);
    event SupplierRegistered(address suppliers);

    
    constructor() public{
        owner=msg.sender;
    }
    
    function registerRetailer() public{
        require(!retailers[msg.sender] && !suppliers[msg.sender],
        "Address already used");
        
        retailers[msg.sender]=true;
        emit RetailerRegistered(msg.sender);
    }
    
    function registerSupplier() public{
        require(!retailers[msg.sender] && !suppliers[msg.sender],
        "Address already used");
        
        suppliers[msg.sender]=true;
        emit SupplierRegistered(msg.sender);
    }
    
    function supplierExists(address s) view public returns (bool) {
        return suppliers[s];
    }
    
    function retailerExists(address r) view public returns (bool) {
        return retailers[r];
    }


}


contract SupplierInventory{
    
    struct inventory_type{
        uint quantity;
        uint price;
    }
    Registration registrationContract;
    mapping(uint=>inventory_type) inventory;
    address owner;
    
    event ItemQuantityUpdated(uint itemNum, uint quantityAvailable);
    
    
    modifier onlyOwner{
        require(msg.sender==owner,
        "Sender not authorized."
        );
        _;
    }  
    
    
    constructor(address registrationAddress)public {
        registrationContract=Registration(registrationAddress);
        
        require (registrationContract.supplierExists(msg.sender),
        "The sender is not an approved supplier");
        
        
        owner=msg.sender;
    }
    
    
    function addItem(uint itemNum, uint quantityOrdered, uint price) public onlyOwner{
        inventory[itemNum].quantity+=quantityOrdered;
        if(price!=0){
            inventory[itemNum].price=price;
        }
        
        emit ItemQuantityUpdated(itemNum, inventory[itemNum].quantity);
    }
    
    
    function deductItem(uint itemNum, uint quantityOrdered) public onlyOwner{
        require (inventory[itemNum].quantity-quantityOrdered>=0,
        "The available inventory is not enough for this order");
        

        inventory[itemNum].quantity-=quantityOrdered;
        emit ItemQuantityUpdated(itemNum, inventory[itemNum].quantity);
    }
    
    function isOwner(address o) view public returns (bool){
        return(o==msg.sender);
    }
    
    function inventoryAvailability(uint itemNum) view public returns(uint){
        return(inventory[itemNum].quantity);
    }
    
}


contract SupplierOrderManagement{
    

    SupplierInventory inventoryContract;
    Registration registrationContract;

    address owner;
    
    event NewPurchaseOrder(address retailer, uint itemNum, uint quantityOrdered);
    
    modifier onlyOwner{
        require(msg.sender==owner,
        "Sender not authorized."
        );
        _;
    }  
    
    modifier onlyRetailer{
        require(registrationContract.retailerExists(msg.sender),
        "Sender not authorized."
        );
        _;
    }  
    
    
    constructor(address inventoryAddress,address registrationAddress)public {
        inventoryContract=SupplierInventory(inventoryAddress);
        registrationContract=Registration(registrationAddress);

        require (inventoryContract.isOwner(msg.sender),
        "The sender is not the owoner of the inventory contract");
        
        
        owner=msg.sender;
    }
    
    
    function PurchaseOrder(uint itemNum, uint quantityOrdered) public onlyRetailer{
        uint quantityAvailable=inventoryContract.inventoryAvailability(itemNum);
        
        require(quantityOrdered<=quantityAvailable,
        "The available inventory is not enough for this order");
        

        inventoryContract.deductItem(itemNum, quantityOrdered);
        
        emit NewPurchaseOrder(msg.sender, itemNum, quantityOrdered);
    }

    
}



contract Reputation{
    

    Registration registrationContract;
    mapping(address=>uint) supplierRep;
    address owner;
    uint cr;
    uint constant adjusting_factor = 4;

    event ReputationUpdated(address supplier, uint repScore);
    
    
    modifier onlyOwner{
        require(msg.sender==owner,
        "Sender not authorized."
        );
        _;
    }  
    
    modifier onlyRetailer{
        require(registrationContract.retailerExists(msg.sender),
        "Sender not authorized."
        );
        _;
    }  
    
    struct retailer_type{
        mapping(address=>bool) suppliers;
        mapping(address=>bool) status;
    }
    
    mapping(address=>retailer_type) retailerFeedback;


    constructor(address registrationAddress)public {
        registrationContract=Registration(registrationAddress);
        
        owner=msg.sender;
    }
    
    
    function addSupplier(address s) public onlyOwner{
        require(supplierRep[s]==0,
        "Supplier already added");
        
        supplierRep[s]=80;
    }
    
    function feedback (address supplier, bool transactionSuccessful) public onlyRetailer {
        require(!retailerFeedback[msg.sender].suppliers[supplier],
        "Retailer has already provided feedback for this supplier"
        );
        require(registrationContract.supplierExists(supplier),
        "Supplier Address is incorrect"
        );
        retailerFeedback[msg.sender].suppliers[supplier]=true;
        retailerFeedback[msg.sender].status[supplier]=transactionSuccessful;
        //calculateRep(supplier);
    }
    
    function calculateRep (address supplier) external {
        
        if(retailerFeedback[msg.sender].status[supplier]){
            cr = (supplierRep[supplier]*95)/(4*adjusting_factor);
            cr /= 100;
            supplierRep[supplier]+=cr;
        }
        else{

            cr = (supplierRep[supplier]*95)/(4*(10-adjusting_factor));
            cr /= 100;
            supplierRep[supplier]-=cr;
        }
        if (supplierRep[supplier]<0){
            supplierRep[supplier]=0;
        }
        else if (supplierRep[supplier]>100){
            supplierRep[supplier]=100;
        }
        
        emit ReputationUpdated(supplier, supplierRep[supplier]);

   }
    

}
