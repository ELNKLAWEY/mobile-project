import { useEffect, useState } from 'react';
import DashboardLayout from '@/components/DashboardLayout';
import DataTable from '@/components/DataTable';
import ConfirmDialog from '@/components/ConfirmDialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
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
import { getUsers, getUser, updateUser, deleteUser, User } from '@/lib/api';
import { MoreHorizontal, Pencil, Trash2, Eye, Loader2, Users as UsersIcon, Phone, MapPin } from 'lucide-react';
import { Badge } from '@/components/ui/badge';

const UsersPage = () => {
  const [users, setUsers] = useState<User[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [editForm, setEditForm] = useState({ name: '', email: '', password: '', phone: '', address: '' });
  const { toast } = useToast();

  const fetchUsers = async () => {
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to fetch users',
        variant: 'destructive',
      });
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleView = async (user: User) => {
    try {
      const fullUser = await getUser(user.id);
      setSelectedUser(fullUser);
      setViewDialogOpen(true);
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to fetch user details',
        variant: 'destructive',
      });
    }
  };

  const handleEdit = (user: User) => {
    setSelectedUser(user);
    setEditForm({
      name: user.name,
      email: user.email,
      password: '',
      phone: user.phone || '',
      address: user.address || '',
    });
    setEditDialogOpen(true);
  };

  const handleDelete = (user: User) => {
    setSelectedUser(user);
    setDeleteDialogOpen(true);
  };

  const submitEdit = async () => {
    if (!selectedUser) return;
    setIsSubmitting(true);
    try {
      const updateData: Partial<User & { password?: string }> = {};
      if (editForm.name !== selectedUser.name) updateData.name = editForm.name;
      if (editForm.email !== selectedUser.email) updateData.email = editForm.email;
      if (editForm.phone !== (selectedUser.phone || '')) updateData.phone = editForm.phone || null;
      if (editForm.address !== (selectedUser.address || '')) updateData.address = editForm.address || null;
      if (editForm.password) updateData.password = editForm.password;

      await updateUser(selectedUser.id, updateData);
      toast({ title: 'Success', description: 'User updated successfully' });
      setEditDialogOpen(false);
      fetchUsers();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to update user',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const confirmDelete = async () => {
    if (!selectedUser) return;
    setIsSubmitting(true);
    try {
      await deleteUser(selectedUser.id);
      toast({ title: 'Success', description: 'User deleted successfully' });
      setDeleteDialogOpen(false);
      fetchUsers();
    } catch (error) {
      toast({
        title: 'Error',
        description: error instanceof Error ? error.message : 'Failed to delete user',
        variant: 'destructive',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const columns = [
    { key: 'id', header: 'ID', className: 'w-16' },
    { key: 'name', header: 'Name' },
    { key: 'email', header: 'Email' },
    {
      key: 'phone',
      header: 'Phone',
      render: (user: User) => user.phone || <span className="text-muted-foreground">-</span>,
    },
    {
      key: 'role',
      header: 'Role',
      render: (user: User) => (
        <Badge variant={user.role === 'ADMIN' ? 'default' : 'secondary'}>
          {user.role}
        </Badge>
      ),
    },
    {
      key: 'created_at',
      header: 'Created',
      render: (user: User) => new Date(user.created_at).toLocaleDateString(),
    },
    {
      key: 'actions',
      header: 'Actions',
      className: 'w-16',
      render: (user: User) => (
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="h-8 w-8">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuItem onClick={() => handleView(user)}>
              <Eye className="h-4 w-4 mr-2" />
              View
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleEdit(user)}>
              <Pencil className="h-4 w-4 mr-2" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem
              onClick={() => handleDelete(user)}
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

  return (
    <DashboardLayout>
      <div className="space-y-6 animate-fade-in">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
              <UsersIcon className="h-6 w-6" />
              Users
            </h1>
            <p className="text-muted-foreground">Manage your application users</p>
          </div>
        </div>

        <DataTable
          columns={columns}
          data={users}
          isLoading={isLoading}
          emptyMessage="No users found"
          keyExtractor={(user) => user.id}
        />

        {/* View Dialog */}
        <Dialog open={viewDialogOpen} onOpenChange={setViewDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>User Details</DialogTitle>
            </DialogHeader>
            {selectedUser && (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <Label className="text-muted-foreground">ID</Label>
                    <p className="font-medium">{selectedUser.id}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Role</Label>
                    <p>
                      <Badge variant={selectedUser.role === 'ADMIN' ? 'default' : 'secondary'}>
                        {selectedUser.role}
                      </Badge>
                    </p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Name</Label>
                    <p className="font-medium">{selectedUser.name}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Email</Label>
                    <p className="font-medium">{selectedUser.email}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground flex items-center gap-1">
                      <Phone className="h-3 w-3" /> Phone
                    </Label>
                    <p className="font-medium">{selectedUser.phone || '-'}</p>
                  </div>
                  <div>
                    <Label className="text-muted-foreground">Created At</Label>
                    <p className="font-medium">
                      {new Date(selectedUser.created_at).toLocaleString()}
                    </p>
                  </div>
                  <div className="col-span-2">
                    <Label className="text-muted-foreground flex items-center gap-1">
                      <MapPin className="h-3 w-3" /> Address
                    </Label>
                    <p className="font-medium">{selectedUser.address || '-'}</p>
                  </div>
                </div>
              </div>
            )}
          </DialogContent>
        </Dialog>

        {/* Edit Dialog */}
        <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>Edit User</DialogTitle>
              <DialogDescription>Update user information</DialogDescription>
            </DialogHeader>
            <div className="space-y-4">
              <div className="space-y-2">
                <Label htmlFor="edit-name">Name</Label>
                <Input
                  id="edit-name"
                  value={editForm.name}
                  onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-email">Email</Label>
                <Input
                  id="edit-email"
                  type="email"
                  value={editForm.email}
                  onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-phone">Phone</Label>
                <Input
                  id="edit-phone"
                  type="tel"
                  value={editForm.phone}
                  onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })}
                  placeholder="01234567890"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-address">Address</Label>
                <Input
                  id="edit-address"
                  value={editForm.address}
                  onChange={(e) => setEditForm({ ...editForm, address: e.target.value })}
                  placeholder="Full address"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="edit-password">New Password (optional)</Label>
                <Input
                  id="edit-password"
                  type="password"
                  placeholder="Leave empty to keep current"
                  value={editForm.password}
                  onChange={(e) => setEditForm({ ...editForm, password: e.target.value })}
                />
              </div>
            </div>
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
          title="Delete User"
          description={`Are you sure you want to delete "${selectedUser?.name}"? This action cannot be undone.`}
          confirmText="Delete"
          onConfirm={confirmDelete}
          isLoading={isSubmitting}
          variant="destructive"
        />
      </div>
    </DashboardLayout>
  );
};

export default UsersPage;
