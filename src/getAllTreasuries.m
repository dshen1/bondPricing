function allTreasuries = getAllTreasuries(dateBeg, dateEnd)
% get array of all treasuries that have auction in a given range
%
% TODO:
% Correct coupon rates need to be determined. For this bond pricing and
% interest rates are required.

% get all TBills
xx1 = getTBill(dateBeg, dateEnd, 4);
xx2 = getTBill(dateBeg, dateEnd, 13);
xx3 = getTBill(dateBeg, dateEnd, 26);
xx4 = getTBill(dateBeg, dateEnd, 52);
allTBills = [xx1; xx2; xx3; xx4];

% get all TNotes and TBonds
xx1 = getTNoteBond(dateBeg, dateEnd, 2);
xx2 = getTNoteBond(dateBeg, dateEnd, 3);
xx3 = getTNoteBond(dateBeg, dateEnd, 5);
xx4 = getTNoteBond(dateBeg, dateEnd, 7);
xx5 = getTNoteBond(dateBeg, dateEnd, 10);
xx6 = getTNoteBond(dateBeg, dateEnd, 30);
allTNotes = [xx1; xx2; xx3; xx4; xx5; xx6];

allTreasuries = [allTBills; allTNotes];

end