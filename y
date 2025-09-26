{
  "indexes": [
    {
      "collectionGroup": "notification%20",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "userId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "DESCENDING"
        },
        {
          "fieldPath": "name",
          "order": "DESCENDING"
        }
      ],
      "density": "SPARSE_ALL"
    }
  ],
  "fieldOverrides": []
}