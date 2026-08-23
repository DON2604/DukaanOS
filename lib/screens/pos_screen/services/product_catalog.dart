import '../models/product.dart';

Map<String, Product> createDefaultCatalog() {
  return {
    '8901063016307': const Product(
      barcode: '8901063016307',
      name: 'Parle-G',
      description: '100g',
      price: 10.00,
      imageUrl:
          'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?w=200&auto=format&fit=crop&q=60',
    ),
    '8901058897089': const Product(
      barcode: '8901058897089',
      name: 'Maggi Masala',
      description: '70g',
      price: 14.00,
      imageUrl:
          'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=200&auto=format&fit=crop&q=60',
    ),
    '8901764012220': const Product(
      barcode: '8901764012220',
      name: 'Coca-Cola',
      description: '750ml',
      price: 40.00,
      imageUrl:
          'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=200&auto=format&fit=crop&q=60',
    ),
    '7622300744111': const Product(
      barcode: '7622300744111',
      name: 'Oreo Vanilla',
      description: '118g',
      price: 20.00,
      imageUrl:
          'https://images.unsplash.com/photo-1558961309-dbdf71799f5a?w=200&auto=format&fit=crop&q=60',
    ),
  };
}
