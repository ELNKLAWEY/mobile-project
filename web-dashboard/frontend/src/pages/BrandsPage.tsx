import { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import DataTable from '@/components/DataTable';
import ConfirmDialog from '@/components/ConfirmDialog';
import ImageUpload from '@/components/ImageUpload';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Progress } from '@/components/ui/progress';
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
import { useToast } from '@/hooks/use-toast';
import {
  getBrands,
  createBrand,
  updateBrand,
  deleteBrand,
  Brand,
} from '@/lib/api';
import {
  MoreHorizontal,
  Pencil,
  Trash2,
  Plus,
  Loader2,
  Tags,
} from 'lucide-react';

const API_BASE = 'https://api.mohamed-osama.cloud';

const getFullImageUrl = (url: string) => {
  if (!url) return '';
  if (url.startsWith('http')) return url;
  return `${API_BASE}${url.startsWith('/') ? '' : '/'}${url}`;
};

const BrandsPage = () => {
  const [brands, setBrands] = useState<Brand[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedBrand, setSelectedBrand] = useState<Brand | null>(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [form, setForm] = useState({ name: '' });
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [currentImageUrl, setCurrentImageUrl] = useState<string>('');
  const { toast } = useToast();

  const fetchBrands = async () => {
    setIsLoading(true);
    try {
      const data = await getBrands();
      setBrands(data);
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to fetch brands',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchBrands();
  }, []);

  const openCreateDialog = () => {
    setForm({ name: '' });
    setImageFile(null);
    setCurrentImageUrl('');
    setUploadProgress(0);
    setCreateDialogOpen(true);
  };

  const handleEdit = (brand: Brand) => {
    setSelectedBrand(brand);
    setForm({ name: brand.name });
    setImageFile(null);
    setCurrentImageUrl(brand.image);
    setUploadProgress(0);
    setEditDialogOpen(true);
  };

  const handleDelete = (brand: Brand) => {
    setSelectedBrand(brand);
    setDeleteDialogOpen(true);
  };

  const submitCreate = async () => {
    if (!form.name) {
      toast({
        title: 'Validation Error',
        description: 'Brand name is required',
        variant: 'destructive',
      });
      return;
    }

    setIsSubmitting(true);
    setUploadProgress(30);
    try {
      await createBrand({
        name: form.name,
        image: imageFile || undefined,
      });
      setUploadProgress(100);
      toast({ title: 'Success', description: 'Brand created successfully' });
      setCreateDialogOpen(false);
      fetchBrands();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to create brand',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  const submitEdit = async () => {
    if (!selectedBrand) return;
    setIsSubmitting(true);
    setUploadProgress(30);
    try {
      await updateBrand(selectedBrand.id, {
        name: form.name,
        ...(imageFile && { image: imageFile }),
      });
      setUploadProgress(100);
      toast({ title: 'Success', description: 'Brand updated successfully' });
      setEditDialogOpen(false);
      fetchBrands();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to update brand',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
      setUploadProgress(0);
    }
  };

  const confirmDelete = async () => {
    if (!selectedBrand) return;
    setIsSubmitting(true);
    try {
      await deleteBrand(selectedBrand.id);
      toast({ title: 'Success', description: 'Brand deleted successfully' });
      setDeleteDialogOpen(false);
      fetchBrands();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to delete brand. Make sure no products are associated with it.',
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
      render: (brand: Brand) => (
        <div className="w-12 h-12 rounded-lg overflow-hidden bg-muted">
          {brand.image ? (
            <img
              src={getFullImageUrl(brand.image)}
              alt={brand.name}
              className="w-full h-full object-cover"
              onError={(e) => {
                (e.target as HTMLImageElement).style.display = 'none';
              }}
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center">
              <Tags className="w-5 h-5 text-muted-foreground" />
            </div>
          )}
        </div>
      ),
    },
    { key: 'name', header: 'Name' },
    {
      key: 'created_at',
      header: 'Created',
      render: (brand: Brand) => new Date(brand.created_at).toLocaleDateString(),
    },
    {
      key: 'actions',
      header: 'Actions',
      className: 'w-16',
      render: (brand: Brand) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => handleEdit(brand)}>
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => handleDelete(brand)}
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

  const renderBrandForm = (isEdit = false) => (
    <div className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">Brand Name *</Label>
        <Input
          id="name"
          value={form.name}
          onChange={(e) => setForm({ ...form, name: e.target.value })}
          placeholder="Brand name"
          disabled={isSubmitting}
        />
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
              <Tags className="h-6 w-6" />
              Brands
            </h1>
            <p className="text-muted-foreground">Manage product brands</p>
          </div>
          <Button onClick={openCreateDialog}>
            <Plus className="h-4 w-4 mr-2" />
            Add Brand
          </Button>
        </div>

        <DataTable
          columns={columns}
          data={brands}
          isLoading={isLoading}
          emptyMessage="No brands found"
          keyExtractor={(brand) => brand.id}
        />

        {/* Create Dialog */}
        <Dialog open={createDialogOpen} onOpenChange={setCreateDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Add Brand</DialogTitle>
              <DialogDescription>Create a new brand</DialogDescription>
            </DialogHeader>
            {renderBrandForm()}
            <DialogFooter>
              <Button variant="outline" onClick={() => setCreateDialogOpen(false)}>
                Cancel
              </Button>
              <Button onClick={submitCreate} disabled={isSubmitting}>
                {isSubmitting && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                Create Brand
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Edit Dialog */}
        <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Edit Brand</DialogTitle>
              <DialogDescription>Update brand information</DialogDescription>
            </DialogHeader>
            {renderBrandForm(true)}
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

        {/* Delete Confirmation */}
        <ConfirmDialog
          open={deleteDialogOpen}
          onOpenChange={setDeleteDialogOpen}
          title="Delete Brand"
          description={`Are you sure you want to delete "${selectedBrand?.name}"? This action cannot be undone. Note: You cannot delete a brand with associated products.`}
          confirmText="Delete"
          onConfirm={confirmDelete}
          isLoading={isSubmitting}
          variant="destructive"
        />
      </div>
    </DashboardLayout>
  );
};

export default BrandsPage;
