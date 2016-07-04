db.collection.mapReduce(
  function () {
    var date = new Date(this.dateEntry.valueOf() -
      ( this.dateEntry.valueOf() % ( 1000 * 60 * 60 * 24 ) )
    );

    emit( date, this.amount );
  },
  function(key,values) {
      return Array.sum( values );
  },
  { 
      "scope": { "total": 0 },
      "finalize": function(key,value) {
          total += value;
          return total;
      },
      "out": { "inline": 1 }
  }
)      