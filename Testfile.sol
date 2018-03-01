pragma solidity ^0.4.0;
contract Test
{
    struct abc
    {
        uint256 pid;
        string pname;
        uint256 pquantity;
        uint256 price;
    }
    uint256 start;
     uint256 End;
    mapping(uint=>abc)key;
    mapping(uint=>mapping(uint=>abc))mainkey;
    function stock_Producdt(uint256 index,uint256 _pid,string _pname,uint256 _pquantity,uint256 price)public
    {
        key[index].pid=_pid;
        key[index].pname=_pname;
        key[index].pquantity=_pquantity;
        key[index].price=price;
    }
    function Test()public
    {
      start=now;   
    }
    function Order_Product(uint256 index,uint256 _cid,uint256 _pid,uint256 _pquantity)public
    {
     End=now;
     require((start-End)>5 seconds && (End-start)<15 seconds);
     mainkey[_cid][_pid].pid=_pid;
     mainkey[_cid][_pid].pquantity=_pquantity;
     key[index].pquantity--;
    }
    function Product_Details(uint256 index)public constant returns(uint256,string,uint256)
    {
        return (key[index].pid,key[index].pname,key[index].pquantity);
    }
    function Purchase_Details(uint256 _cid,uint256 _pid,uint256 index)public constant returns(uint256,string,uint256,uint256)
    {
        return ( mainkey[_cid][_pid].pid,key[index].pname,mainkey[_cid][_pid].pquantity,mainkey[_cid][_pid].pquantity*key[index].price);
    }
}
