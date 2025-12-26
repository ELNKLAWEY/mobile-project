import { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import DataTable from '@/components/DataTable';
import ConfirmDialog from '@/components/ConfirmDialog';
import ImageUpload from '@/components/ImageUpload';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import {
  getProducts,
  createProduct,
  updateProduct,
  deleteProduct,
  getBrands,
  getProductRatings,
  deleteRating,
  Product,
  ProductsResponse,
  Brand,
  ProductRatingsResponse,
} from '@/lib/api';
import {
  MoreHorizontal,
  Pencil,
  Trash2,
  Plus,
  Loader2,
  Package,
  Search,
  X,
  Star,
} from 'lucide-react';

const API_BASE = 'https://api.mohamed-osama.cloud';

const getFullImageUrl = (url: string) => {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  return `${API_BASE}${url.startsWith('/') ? '' : '/'}${url}`;
};

const ProductsPage = () => {
  const [productsResponse, setProductsResponse] = useState<ProductsResponse | null>(null);
  const [brands, setBrands] = useState<Brand[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [ratingsDialogOpen, setRatingsDialogOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [search, setSearch] = useState('');
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [form, setForm] = useState({
    title: '',
    description: '',
    price: '',
    stock: '',
    brand_id: '',
  });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [currentImageUrl, setCurrentImageUrl] = useState<string>('');
  const [ratingsData, setRatingsData] = useState<ProductRatingsResponse | null>(null);
  const [loadingRatings, setLoadingRatings] = useState(false);
  const { toast } = useToast();

  const fetchProducts = async () => {
    setIsLoading(true);
    try {
      const data = await getProducts({
        search: search || undefined,
        min_price: minPrice ? parseFloat(minPrice) : undefined,
        max_price: maxPrice ? parseFloat(maxPrice) : undefined,
        page: currentPage,
        limit: 10,
      });
      setProductsResponse(data);
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to fetch products',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  const fetchBrands = async () => {
    try {
      const data = await getBrands();
      setBrands(data);
    } catch (error) {
      console.error('Failed to fetch brands:', error);
    }
  };

  useEffect(() => {
    fetchProducts();
    fetchBrands();
  }, [currentPage]);

  const handleSearch = () => {
    setCurrentPage(1);
    fetchProducts();
  };

  const clearFilters = () => {
    setSearch('');
    setMinPrice('');
    setMaxPrice('');
    setCurrentPage(1);
    setTimeout(fetchProducts, 0);
  };

  const openCreateDialog = () => {
    setForm({ title: '', description: '', price: '', stock: '', brand_id: '' });
    setImageFile(null);
    setCurrentImageUrl('');
    setUploadProgress(0);
    setCreateDialogOpen(true);
  };

  const handleEdit = (product: Product) => {
    setSelectedProduct(product);
    setForm({
      title: product.title,
      description: product.description,
      price: product.price,
      stock: product.stock.toString(),
      brand_id: product.brand_id?.toString() || '',
    });
    setImageFile(null);
    setCurrentImageUrl(product.image);
    setUploadProgress(0);
    setEditDialogOpen(true);
  };

  const handleDelete = (product: Product) => {
    setSelectedProduct(product);
    setDeleteDialogOpen(true);
  };

  const handleViewRatings = async (product: Product) => {
    setSelectedProduct(product);
    setRatingsDialogOpen(true);
    setLoadingRatings(true);
    try {
      const data = await getProductRatings(product.id);
      setRatingsData(data);
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to fetch ratings',
        variant: 'destructive',
      });
    } finally {
      setLoadingRatings(false);
    }
  };

  const handleDeleteRating = async (ratingId: number) => {
    try {
      await deleteRating(ratingId);
      toast({ title: 'Success', description: 'Rating deleted successfully' });
      if (selectedProduct) {
        const data = await getProductRatings(selectedProduct.id);
        setRatingsData(data);
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to delete rating',
        variant: 'destructive',
      });
    }
  };

  const submitCreate = async () => {
    if (!form.title || !form.price) {
      toast({
        title: 'Validation Error',
        description: 'Title and price are required',
        variant: 'destructive',
      });
      return;
    }

    if (!imageFile) {
      toast({
        title: 'Validation Error',
        description: 'Product image is required',
        variant: 'destructive',
      });
      return;
    }

    setIsSubmitting(true);
    setUploadProgress(30);
    try {
      await createProduct({
        title: form.title,
        description: form.description,
        price: form.price,
        stock: parseInt(form.stock) || 0,
        brand_id: form.brand_id ? parseInt(form.brand_id) : null,
        image: imageFile,
      });
      setUploadProgress(100);
      toast({ title: 'Success', description: 'Product created successfully' });
      setCreateDialogOpen(false);
      fetchProducts();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to create product',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  const submitEdit = async () => {
    if (!selectedProduct) return;
    setIsSubmitting(true);
    setUploadProgress(30);
    try {
      await updateProduct(selectedProduct.id, {
        title: form.title,
        description: form.description,
        price: form.price,
        stock: parseInt(form.stock) || 0,
        brand_id: form.brand_id ? parseInt(form.brand_id) : null,
        ...(imageFile && { image: imageFile }),
      });
      setUploadProgress(100);
      toast({ title: 'Success', description: 'Product updated successfully' });
      setEditDialogOpen(false);
      fetchProducts();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to update product',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  const confirmDelete = async () => {
    if (!selectedProduct) return;
    setIsSubmitting(true);
    try {
      await deleteProduct(selectedProduct.id);
      toast({ title: 'Success', description: 'Product deleted successfully' });
      setDeleteDialogOpen(false);
      fetchProducts();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to delete product',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns = [
    { key: 'id', header: 'ID', className: 'w-16' },
    {
      key: 'image',
      header: 'Image',
      className: 'w-20',
      render: (product: Product) => (
        <div className="w-12 h-12 rounded-lg overflow-hidden bg-muted">
          {product.image ? (
            <img
              src={getFullImageUrl(product.image)}
              alt={product.title}
              className="w-full h-full object-cover"
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = 'none';
              }}
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <Package className="w-5 h-5 text-muted-foreground" />
            </div>
          )}
        </div>
      ),
    },
    { key: 'title', header: 'Title' },
    {
      key: 'brand',
      header: 'Brand',
      render: (product: Product) => product.brand_name ? (
        <Badge variant="secondary">{product.brand_name}</Badge>
      ) : (
        <span className="text-muted-foreground">-</span>
      ),
    },
    {
      key: 'price',
      header: 'Price',
      render: (product: Product) => `$${parseFloat(product.price).toFixed(2)}`,
    },
    { key: 'stock', header: 'Stock' },
    {
      key: 'actions',
      header: 'Actions',
      className: 'w-16',
      render: (product: Product) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => handleViewRatings(product)}>
              <Star className="h-4 w-4 mr-2" />
              View Ratings
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleEdit(product)}>
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => handleDelete(product)}
              className="text-destructive focus:text-destructive"
            >
              <Trash2 className="h-4 w-4 mr-2" />
              Delete
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      ),
    },
  ];

  const renderProductForm = (isEdit = false) => (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="title">Title *</Label>
        <Input
          id="title"
          value={form.title}
          onChange={(e) => setForm((prev) => ({ ...prev, title: e.target.value }))}
          placeholder="Product title"
          disabled={isSubmitting}
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="description">Description *</Label>
        <Textarea
          id="description"
          value={form.description}
          onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))}
          placeholder="Product description"
          rows={3}
          disabled={isSubmitting}
        />
      </div>
      <div className="space-y-2">
        <Label htmlFor="brand">Brand</Label>
        <Select
          value={form.brand_id || "none"}
          onValueChange={(value) => setForm((prev) => ({ ...prev, brand_id: value === "none" ? "" : value }))}
          disabled={isSubmitting}
        >
          <SelectTrigger>
            <SelectValue placeholder="Select a brand (optional)" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="none">No Brand</SelectItem>
            {brands.map((brand) => (
              <SelectItem key={brand.id} value={brand.id.toString()}>
                {brand.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>
      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-2">
          <Label htmlFor="price">Price *</Label>
          <Input
            id="price"
            type="number"
            step="0.01"
            value={form.price}
            onChange={(e) => setForm((prev) => ({ ...prev, price: e.target.value }))}
            placeholder="99.99"
            disabled={isSubmitting}
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="stock">Stock *</Label>
          <Input
            id="stock"
            type="number"
            value={form.stock}
            onChange={(e) => setForm((prev) => ({ ...prev, stock: e.target.value }))}
            placeholder="0"
            disabled={isSubmitting}
          />
        </div>
      </div>
      <ImageUpload
        value={imageFile}
        onChange={setImageFile}
        currentImageUrl={isEdit ? currentImageUrl : undefined}
        disabled={isSubmitting}
      />
      {isSubmitting && uploadProgress > 0 && (
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground">Uploading...</span>
            <span className="text-muted-foreground">{uploadProgress}%</span>
          </div>
          <Progress value={uploadProgress} className="h-2" />
        </div>
      )}
    </div>
  );

  return (
    <DashboardLayout>
      <div className="space-y-6 animate-fade-in">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
              <Package className="h-6 w-6" />
              Products
            </h1>
            <p className="text-muted-foreground">Manage your product catalog</p>
          </div>
          <Button onClick={openCreateDialog}>
            <Plus className="h-4 w-4 mr-2" />
            Add Product
          </Button>
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-4 p-4 bg-card rounded-lg border border-border">
          <div className="flex-1 min-w-[200px]">
            <Input
              placeholder="Search products..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            />
          </div>
          <div className="w-32">
            <Input
              placeholder="Min price"
              type="number"
              value={minPrice}
              onChange={(e) => setMinPrice(e.target.value)}
            />
          </div>
          <div className="w-32">
            <Input
              placeholder="Max price"
              type="number"
              value={maxPrice}
              onChange={(e) => setMaxPrice(e.target.value)}
            />
          </div>
          <Button onClick={handleSearch}>
            <Search className="h-4 w-4 mr-2" />
            Search
          </Button>
          {(search || minPrice || maxPrice) && (
            <Button variant="ghost" onClick={clearFilters}>
              <X className="h-4 w-4 mr-2" />
              Clear
            </Button>
          )}
        </div>

        <DataTable
          columns={columns}
          data={productsResponse?.products || []}
          isLoading={isLoading}
          emptyMessage="No products found"
          keyExtractor={(product) => product.id}
        />

        {/* Pagination */}
        {productsResponse && productsResponse.pagination.pages > 1 && (
          <div className="flex items-center justify-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage === 1}
            >
              Previous
            </Button>
            <span className="text-sm text-muted-foreground">
              Page {currentPage} of {productsResponse.pagination.pages}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.min(productsResponse.pagination.pages, p + 1))}
              disabled={currentPage === productsResponse.pagination.pages}
            >
              Next
            </Button>
          </div>
        )}

        {/* Create Dialog */}
        <Dialog open={createDialogOpen} onOpenChange={setCreateDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add Product</DialogTitle>
              <DialogDescription>Create a new product in your catalog</DialogDescription>
            </DialogHeader>
            {renderProductForm(false)}
            <DialogFooter>
              <Button variant="outline" onClick={() => setCreateDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={submitCreate} disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Create Product
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Edit Dialog */}
        <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Edit Product</DialogTitle>
              <DialogDescription>Update product information</DialogDescription>
            </DialogHeader>
            {renderProductForm(true)}
            <DialogFooter>
              <Button variant="outline" onClick={() => setEditDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={submitEdit} disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Save Changes
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Ratings Dialog */}
        <Dialog open={ratingsDialogOpen} onOpenChange={setRatingsDialogOpen}>
          <DialogContent className="max-w-2xl">
            <DialogHeader>
              <DialogTitle>Product Ratings</DialogTitle>
              <DialogDescription>{selectedProduct?.title}</DialogDescription>
            </DialogHeader>
            {loadingRatings ? (
              <div className="flex items-center justify-center py-8">
                <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
              </div>
            ) : ratingsData ? (
              <div className="space-y-4">
                <div className="flex items-center gap-4 p-4 bg-muted/30 rounded-lg">
                  <div className="flex items-center gap-1">
                    <Star className="h-6 w-6 fill-yellow-400 text-yellow-400" />
                    <span className="text-2xl font-bold">{ratingsData.average_rating.toFixed(1)}</span>
                  </div>
                  <span className="text-muted-foreground">
                    {ratingsData.total_ratings} review{ratingsData.total_ratings !== 1 ? 's' : ''}
                  </span>
                </div>
                {ratingsData.ratings.length === 0 ? (
                  <p className="text-center text-muted-foreground py-4">No ratings yet</p>
                ) : (
                  <div className="space-y-3 max-h-[400px] overflow-y-auto">
                    {ratingsData.ratings.map((rating) => (
                      <div key={rating.id} className="flex items-start gap-3 p-3 bg-muted/20 rounded-lg">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <span className="font-medium">{rating.user_name || `User #${rating.user_id}`}</span>
                            <div className="flex items-center gap-0.5">
                              {Array.from({ length: 5 }).map((_, i) => (
                                <Star
                                  key={i}
                                  className={`h-3 w-3 ${i < rating.rating ? 'fill-yellow-400 text-yellow-400' : 'text-muted'}`}
                                />
                              ))}
                            </div>
                          </div>
                          {rating.comment && (
                            <p className="text-sm text-muted-foreground">{rating.comment}</p>
                          )}
                          <p className="text-xs text-muted-foreground mt-1">
                            {new Date(rating.created_at).toLocaleDateString()}
                          </p>
                        </div>
                        <Button
                          variant="ghost"
                          size="icon"
                          className="h-8 w-8 text-destructive hover:text-destructive"
                          onClick={() => handleDeleteRating(rating.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ) : null}
          </DialogContent>
        </Dialog>

        {/* Delete Confirmation */}
        <ConfirmDialog
          open={deleteDialogOpen}
          onOpenChange={setDeleteDialogOpen}
          title="Delete Product"
          description={`Are you sure you want to delete "${selectedProduct?.title}"? This action cannot be undone.`}
          confirmText="Delete"
          onConfirm={confirmDelete}
          isLoading={isSubmitting}
          variant="destructive"
        />
      </div>
    </DashboardLayout>
  );
};

export default ProductsPage;
